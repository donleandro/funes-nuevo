/* 
 * 
 * Javascript files are loaded in alphabetic order, hence the "90" 
 * in the filename to force it to load after the other files!
 * 
 * 
*/

var xmlHttp; //This here global is the request object what is used to call and retrieve data from scripts
var request_script; // This here global is the script what is to be requested
var objecttype; // This here global is the script what is to be requested

var wait_element;
var xmlConfig; //This is the object into which the sneep.xls stuff is parsed.
var textLength=0; //this is used to expand the textarea... not sure how to handle when there are multiple textareas to expand
var objects_str="eprint:document:user:comment";
var objects = objects_str.split(":");
var logged_in = false;
var cgi_path = "/cgi";
//************* These two do most of the xmlhttprequest magic **********/
function loadXMLDoc(url,params)
{
    // branch for native XMLHttpRequest object
	try{
    	// Firefox, Opera 8.0+, Safari
    		xmlHttp=new XMLHttpRequest();
	} catch (e) {
	// Internet Explorer
    		try{
		      xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");
      		} catch (e) {
		      try{
		        xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
		        } catch (e) {
			        alert("Your browser does not support AJAX!");
			        return false;
        		}
      		}
    	}
	//alert(url+ ": "+params);
    	xmlHttp.onreadystatechange = processReqChange;
	xmlHttp.open("POST",url,true);

	//Send the proper header information along with the request
	xmlHttp.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
	xmlHttp.setRequestHeader("Content-length", params.length);
	xmlHttp.setRequestHeader("Connection", "close");

	xmlHttp.send(params);
}

function processReqChange()
{
    	// only if req shows "complete"
    	if (xmlHttp.readyState == 4) {
		// only if "OK"
		if (xmlHttp.status == 200) {
			if(wait_element)
				Effect.Fade(wait_element);
	                // ...processing statements go here... replace these ifs with an eval at some point
			if(request_script == "comment"){				
				process_comment();
			}
			if(request_script == "tag"){
				process_tag();
			}
			if(request_script == "note"){
				process_note();
			}

                } else {
                        alert("There was a problem retrieving the XML data:\n" + xmlHttp.statusText);
		}
	}else{
		if(wait_element)
			Effect.Appear(wait_element);
	}
}
function parse_post(text)
{
	var parsing_text = "<temp_parsing_tag>"+text+"</temp_parsing_tag>";	
	// code for IE
	if (window.ActiveXObject){
		var doc=new ActiveXObject("Microsoft.XMLDOM");
		doc.async="false";
		doc.loadXML(parsing_text);
	}else{
		// code for Mozilla, Firefox, Opera, etc.
		var parser=new DOMParser();
		var doc=parser.parseFromString(parsing_text,"text/xml");
	}
	var roottag = doc.documentElement;
	if(!roottag){
		var err_msg = "Parsing Error: "+doc.parseError.reason+"\rOn line: "+doc.parseError.line;
		alert(err_msg);
		return false;
	}
	if ((roottag.tagName == "parserError") || (roottag.namespaceURI == "http://www.mozilla.org/newlayout/xml/parsererror.xml")){
		var err_msg = roottag.firstChild.data.split("\n",1)[0]+"\n"+roottag.firstChild.data.split("\n",3)[2];
		alert(err_msg);
		return false;
	}
	return true;
}

function log_in_to_edit(rs)
{
	
	var add_form_div = document.getElementById("sneep_"+rs.charAt(0)+"_add:"+objecttype);
	var add_form_div_textarea = document.getElementById("sneep_"+rs.charAt(0)+"_add_textarea:"+objecttype);

	add_form_div.style.fontSize = '100%';
	add_form_div.innerHTML = "<p class=\"sneep_message\">Ud. debe ingresar para editar comentarios.</p>";
	add_form_div_textarea.style.display = "none";
}
function log_in_to_view(rs)
{
	document.getElementById("sneep_"+rs.charAt(0)+"_main:"+objecttype).innerHTML="<p class=\"sneep_message\">Ud. debe ingresar para ver.</p>";
}
function log_in_to_add(rs)
{
//	document.getElementById("sneep_"+rs.charAt(0)+"_main:"+objecttype).innerHTML="<p class=\"sneep_message\">Ud. debe ingresar para agregar.</p>";
	alert("Ud. debe ingresar para agregar.");
	return false;
}

function get_params(action, id, rs)
{
	var params ="";
	if(action.match("Update")){
		var edited_text = document.getElementById("sneep_"+rs.charAt(0)+"_edit_textarea_"+id+":"+objecttype).value;
		var original_text = document.getElementById("sneep_"+rs.charAt(0)+"_text_"+id+":"+objecttype).innerHTML;
		//If there has been a change in the text (or title) and the admin flag is set display a 
		//message letting the users know that the admin has edited the post
		if(document.getElementById("admin_edit_"+id+":"+objecttype) && edited_text != original_text){
			var repo_admin = document.getElementById("repo_admin_email").innerHTML;
			edited_text += "<div class=\"sneep_admin_intervention\">This "+request_script+" has been edited by the <a href=\"mailto:"+repo_admin+"\">repository administrator</a>.</div>";
		}
		var edited_title = false;
		if(document.getElementById("sneep_"+rs.charAt(0)+"_edit_title_"+id+":"+objecttype)){
			edited_title = document.getElementById("sneep_"+rs.charAt(0)+"_edit_title_"+id+":"+objecttype).value;
			var original_title = document.getElementById("sneep_"+rs.charAt(0)+"_title_"+id+":"+objecttype).innerHTML;	
			if(document.getElementById("admin_edit_"+id) && edited_title != original_title){
				var repo_admin = document.getElementById("repo_admin_email").innerHTML;
				edited_text += "<div class=\"sneep_admin_intervention\">The title of this "+request_script+" has been edited by the <a href=\"mailto:"+repo_admin+"\">repository administrator</a>.</div>";
			}
		}

		if(!parse_post(edited_text) || edited_title && !parse_post(edited_title)){
			return -1;
		}
		params += request_script+"id="+id+"&text="+encodeURI(edited_text);
		if(edited_title){
			params += "&title="+encodeURI(edited_title);
		}
	}
	if(action.match("Add")){
		params += "text="+encodeURI(document.getElementById("sneep_new_"+request_script+"_text:"+objecttype).value);
		if(document.getElementById("sneep_new_"+request_script+"_title:"+objecttype)){
			params += "&title="+encodeURI(document.getElementById("sneep_new_"+request_script+"_title:"+objecttype).value);
		}
	}
	if(action.match("Delete")){
		// If admin is deleting this ... don't actually delete it... edit it into oblivion instead
		if(document.getElementById("admin_edit_"+id+":"+objecttype)){
			var repo_admin = document.getElementById("repo_admin_email").innerHTML;
			var edited_text = "<div class=\"sneep_admin_intervention\">This "+request_script+" has been removed by the <a href=\"mailto:"+repo_admin+"\">repository administrator</a>.</div>";
			params += request_script+"id="+id+"&text="+edited_text;
		}else{
			params += request_script+"id="+id;
		}
	}	
//	alert("params: "+params);
	return params;
}
function get_url(open, action, logged_in, objectid, id, id_type)
{

	var url = cgi_path;

	if(open==1 && !logged_in){
		url += "/"+request_script+"/"+objectid+"/"+id_type+"/";
	}else if(logged_in){
		url += "/users/"+request_script+"/"+objectid+"/"+id_type+"/";
	}else{
		return false;
	}
	
	if(action.match("Update")){
		url +=action;
	}else if(action.match("Add")){
		url +=action;
	}else if(action.match("Delete")){
		// If admin is deleting this comment don't actually delete it... edit it into oblivion instead
		if(document.getElementById("admin_edit_"+id+":"+objecttype)){
			url = cgi_path+"/users/"+request_script+"/"+objectid+"/Update";
		}else{
			url +=action;
		}
	}
//	alert("url: "+url);
	return url;
}
/*
function expandTextArea(textarealabel, e)
{
	if(!textarealabel.textLength)
		textLength=textarealabel.value.length;
	else
		textLength=textarealabel.textLength;

	var textareaWidth=textarealabel.cols;
	 //adjust down for IE (stop it getting to end of box and flashing scroll bars.
	if(browser=="Microsoft Internet Explorer"){
		textareaWidth-=5;
	}
	if ((textLength % textareaWidth == 0) && (textLength > 1 )){
		if (e.which == 8)
			textarealabel.rows = textarealabel.rows-1;
		else
			textarealabel.rows = textarealabel.rows+1;
		
		textLength=0;
	}
}
*/
//Although this version resets the textarea rows on every key up I prefer it to the commented out one above.
function setTextArea(textarealabel)
{
	if(!textarealabel.textLength)
		textLength=textarealabel.value.length;
	else
		textLength=textarealabel.textLength;
	var textareaWidth=textarealabel.cols;
	
	var rows = parseInt(textLength/textareaWidth);
	textarealabel.rows = rows+2;
}
//this function is a scriptalicious callback which grabs the frist textarea it comes to 
//in a newly appearred element and focuses on it.
function focusAfterAppear(obj)
{
       	var textarea = obj.element.getElementsByTagName('textarea')[0];
	textarea.focus();
}
function crossFloat(element, value){

        if(browser.match("Microsoft")){
		element.style.styleFloat = value;
	}else{
		element.style.cssFloat = value;
	}
}
function columnLayout(obj)
{
	// Check the status of other components and adjust style elements accordingly
	var sneep_toolbar = document.getElementById( "sneep_toolbar:"+objecttype );
	var statii = sneep_toolbar.getElementsByTagName("span");
	var this_str = obj.element.id.split("_main")[0];

	for(var i=0; i<statii.length; i++){
 
		if(statii[i].id.match(/status_flag/) && statii[i].id != this_str+"_status_flag:"+objecttype && !statii[i].firstChild.data.match("0")){
			var other_str = statii[i].id.split("_status_flag")[0];
			var other_component = document.getElementById(other_str+"_main:"+objecttype);
			obj.element.style.width = '50%';
			if(statii[i].firstChild.data.match("right")){
				crossFloat(obj.element, 'left');
			}else{
				crossFloat(obj.element, 'right');
			}
			crossFloat(other_component, statii[i].firstChild.data);
			other_component.style.width = '50%';
		}
	}
}
function revertLayout(obj)
{
	// Check the status of other components and adjust style elements accordingly
	var sneep_toolbar = document.getElementById( "sneep_toolbar:"+objecttype );
	var statii = sneep_toolbar.getElementsByTagName("span");
	var this_str = obj.element.id.split("_main")[0];
	for(var i=0; i<statii.length; i++){
		if(statii[i].id.match(/status_flag/) && statii[i].id != this_str+"_status_flag:"+objecttype && !statii[i].firstChild.data.match("0")){
			var other_str = statii[i].id.split("_status_flag")[0];
			var other_component = document.getElementById(other_str+"_main:"+objecttype);
			crossFloat(other_component, 'left');
			other_component.style.width = '100%';
			obj.element.style.width = '100%';
		}
	}
}

// Gets the last text node in an element
function get_lastText(n)
{
	var x=n.lastChild;
	while (x.nodeType!=3)
	{
		//alert("text in "+n.id+": "+x.data);
		x=x.previousSibling;
	}

	return x;
}

// Gets the first text node in an element
function get_firstText(n)
{
	var x=n.firstChild;
	while (x.nodeType!=3)
	{
	  x=x.nextSibling;
	}

	return x;
}

