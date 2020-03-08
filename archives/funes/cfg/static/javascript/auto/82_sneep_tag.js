var objectid;

function process_tag()
{
	var tag_msg = document.getElementById("sneep_tag_msg:"+objecttype);
	// code for IE
	if (window.ActiveXObject){
		var doc=new ActiveXObject("Microsoft.XMLDOM");
		doc.async="false";
		doc.loadXML(xmlHttp.responseText);
	}else{
		// code for Mozilla, Firefox, Opera, etc.
		var parser=new DOMParser();
		var doc=parser.parseFromString(xmlHttp.responseText,"text/xml");
	}
	if(doc.getElementsByTagName("sneep_tag_error").length  || doc.getElementsByTagName("sneep_tag_message").length){
		tag_msg.innerHTML = "";
	}

	if(doc.getElementsByTagName("sneep_tag_error").length){
		var errs = doc.getElementsByTagName("sneep_tag_error")
		for(var i=0; i < errs.length; i++){
			var err_msg_span = document.createElement("li");
			var err_msg_str = errs[i].firstChild.nodeValue;
			err_msg_span.appendChild(document.createTextNode(err_msg_str));
			err_msg_span.setAttribute("class","sneep_tag_error_li");
			tag_msg.appendChild(err_msg_span);
		}
	}
	if(doc.getElementsByTagName("sneep_tag_message").length){
		var msgs = doc.getElementsByTagName("sneep_tag_message");
		var filter = document.getElementById("sneep_t_filter_flag:"+objecttype).innerHTML;
		var view = document.getElementById("sneep_t_view_flag:"+objecttype).innerHTML;

		for(var i=0; i < msgs.length; i++){
			var new_tag_text = doc.getElementsByTagName("sneep_tag_message")[0].getAttribute('sneep_tag_text');
			var tag_msg_span = document.createElement("li");
			var tag_msg_str = msgs[i].firstChild.nodeValue;
			tag_msg_span.appendChild(document.createTextNode(tag_msg_str));
			tag_msg_span.setAttribute("class","sneep_tag_message_li");
			tag_msg.appendChild(tag_msg_span);
		}
//		setTimeout("sneepHighlightNewTag('"+new_tag_text+"')",1250);

	}
	if(doc.getElementsByTagName("sneep_tag_message").length==0 && doc.getElementsByTagName("sneep_tag_error").length==0){
	 	var view_div = document.getElementById("sneep_tag_view:"+objecttype);
		view_div.innerHTML = xmlHttp.responseText;
		Effect.Appear(view_div);
		return;
	}else{
		Effect.Appear(tag_msg, {afterFinish: Effect.Fade(tag_msg, {delay: 3})});
		if(doc.getElementsByTagName("sneep_tag_message").length){
			sneep_tag(view,objecttype,objectid,'sneep_wait_cloud', false, filter);
		}
	}
}
function sneepHighlightNewTag(new_tag_text){
	var new_tag = document.getElementById("sneep_tag_tag:"+new_tag_text);
	//new_tag.style.display="none";
//	Effect.Appear(new_tag);
//	Effect.Highlight("sneep_tag_tag:"+new_tag_text, {startcolor:'#ff99ff', endcolor:'#99999);
	Effect.Highlight("sneep_tag_tag:"+new_tag_text);


}
function SneepTagAdd(objecttype, objectid, wait_id)
{
	sneep_tag( 'insert', objecttype, objectid, wait_id);
}

/*
function SneepTagUpdate(objecttype, objectid, noteid, wait_id)
{
	sneep_note( 'Update', objecttype, objectid, wait_id, noteid);
}
*/
function sneepTagDelete(objecttype, objectid, tagid, wait_id)
{
	var r = confirm("Are you sure you want to delete this tag?");
	if(r){
		sneep_tag( 'delete', objecttype, objectid, wait_id, tagid);
	}else{
		return false;
	}
}

function sneep_tag(action, object_type, id, wait_id, tagid, filter, link)
{
	if(wait_id){
		wait_element = document.getElementById(wait_id);
	}
	objectid=id;
	//globablise the objecttype (objectytype defined in 79_sneep)...
	objecttype = object_type.toLowerCase();
	if(!id){
		id = document.getElementById("sneep_t_item_flag:"+objecttype).innerHTML;
	}
	if(!object_type){
		var switched = sneep_tag_eprint(action, id, tagid, filter,link);
		return switched;
	}else{
		object_type = object_type.toLowerCase();
		var cmd = "var switched = sneep_tag_"+object_type+"(action, id, tagid, filter, link);";
		eval(cmd);
		return switched;
	}	
}

function sneep_tag_eprint(action, eprintid, tagid, filter, link)
{
	request_script = "tag";
	if(!eprintid){
		eprintid="global"; //not ideal but works for situations where eprintid is not needed.
	}

	// Is the user logged in? if not they may (depending on the open flag) be able to view but not update
	var logged_in = false;
	if(document.getElementById("logged_in")){
		logged_in = true;
	}
//	alert("action: "+action+", eprintid: "+eprintid+", tagid: "+tagid+", filter: "+filter)
	var open = 0;
	var url;
	var params = "";
	if((!action || action == undefined) && (!filter || filter == undefined)){
		filter = document.getElementById("sneep_t_filter_flag:"+objecttype).innerHTML;
		action = document.getElementById("sneep_t_view_flag:"+objecttype).innerHTML;
	}
	if((filter =="myItemTags" || filter == "myTags") &&  !logged_in){
		log_in_to_view_myTags(request_script);
		return false;
	}else if((action =="insert" || action == "delete") && !logged_in){
		log_in_to_add(request_script);
		return false;
	}

	var global_view_title = document.getElementById("tag_global_view_title");
	var global_tag_filter = document.getElementById("tag_global_filter");
	var global_tag_view = document.getElementById("tag_global_view");

	if(global_view_title && link){
		if(filter && filter.match("allTags"))
			filter_label = "All";
		else
			filter_label = document.getElementById("sneep_t_current_user").innerHTML+"'s";
	
		view_label = "("+action.replace("~","")+")";

		if(!global_tag_filter && !global_tag_view){
			global_view_title.innerHTML = "<span id=\"tag_global_filter\">"+filter_label+"</span> tags for this repository <span id=\"tag_global_view\">"+view_label+"</span>";
		}else{
			global_tag_filter.innerHTML = filter_label;
			global_tag_view.innerHTML = view_label;
		}

		if(!action.match(/~/))
			global_view_title.innerHTML = link.title;
		
	}

	//alert("action: "+action+ " filter: "+filter);
	if(action == "~cloud" || action == "~list"){
			if(filter =="myItemTags" || filter == "myTags"){
				url = cgi_path+"/users/"+request_script;
				url +="/"+eprintid;
				url +="/EPrint/"+action+"/"+filter;
			}else{
				url = cgi_path+"/"+request_script;
				url+="/"+eprintid;
				url +="/EPrint/"+action;
				if(filter){
					url += "/"+filter;
				}
			}
	}else if(action =="insert"){
		url = get_url(open, action, logged_in, eprintid, tagid, 'EPrint');
		url+="insert";
		params = "tag_text="+encodeURI(document.getElementById("sneep_new_tag_title:eprint").value);
	}else if(action == 'delete'){
		url = cgi_path+"/users/"+request_script+"/"+eprintid+"/EPrint/"+action+"/"+tagid;
		//alert(url);
	}else{
		url = cgi_path+"/"+request_script;
		url+="/"+eprintid;
		url +="/EPrint/"+action;
	}

	if(!url){
		alert("I could not retrieve the url of the script that I'm meant to call");
		return false;
	}
//	alert(url+", "+params);	
	if(params != -1 ){
		loadXMLDoc(url,params);
	}else{
		return false;
	}
	return true;
}
function log_in_to_view_myTags(rs)
{
//	document.getElementById("sneep_"+rs.charAt(0)+"_main:"+objecttype).innerHTML="<p class=\"sneep_message\">Ud. debe ingresar para ver.</p>";
	alert("Ud. debe ingresar para ver.");
	return false;
}

function sneep_tag_init()
{
	var n;
	for(n in objects){
		if(!document.getElementById('sneep_t_main:'+objects[n])){continue;}
		var tag_box = document.getElementById('sneep_t_main:'+objects[n]);
		tag_box.style.display = 'none';
	        browser=navigator.appName;
	        b_version=navigator.appVersion;
	        version=parseFloat(b_version);
	        // Opera renders buttons one pixel higher than input-submits so move the bloody things...
	        if(browser == "Opera"){
	                var inputs = document.getElementsByTagName("button");
	                for(var i=0; i<inputs.length; i++){
	                        inputs[i].style.position = 'relative';
	                        inputs[i].style.top = '1px';
	                }
	        }
	}
}

function sneep_tag_init_tag()
{
	var n;
	for(n in objects){
		if(!document.getElementById('sneep_t_main:'+objects[n])){continue;}
		var tag_box = document.getElementById('sneep_t_main:'+objects[n]);

		tag_box.style.display = 'none';
	        browser=navigator.appName;
	        b_version=navigator.appVersion;
	        version=parseFloat(b_version);
	        // Opera renders buttons one pixel higher than input-submits so move the bloody things...
	        if(browser == "Opera"){
	                var inputs = document.getElementsByTagName("button");
	                for(var i=0; i<inputs.length; i++){
	                        inputs[i].style.position = 'relative';
	                        inputs[i].style.top = '1px';
	                }
	        }
		sneep_tag_toggle("sneep_t_main:"+objects[n],document.getElementById("sneep_tag_link:"+objects[n]),"Tag this "+objects[n].ucFirst(), "Cancel", objects[n]);
	}
}
String.prototype.ucFirst = function () {
   return this.substr(0,1).toUpperCase() + this.substr(1,this.length);
}
//This toggles the whole tag box from a link on the abstract page
function sneep_tag_toggle(element_id,button,show,hide, object_type, objectid)
{
        var element = document.getElementById(element_id);
        var button_text;
	objecttype = object_type.toLowerCase();
	var filter = document.getElementById("sneep_t_filter_flag:"+objecttype).innerHTML;
	var view = document.getElementById("sneep_t_view_flag:"+objecttype).innerHTML;

        if(button.tagName.match('INPUT')){
                button_text = button.value;
        }else{
                button_text = button.innerHTML;
        }

        if(button_text.match(hide)){
              	Effect.BlindUp(element);
		switched = sneep_tag(view,objecttype,objectid,'sneep_wait_view', false, filter);
                if(button.tagName.match('INPUT')){
                        button.value = show;
                }else{
                        button.innerHTML = show;
                }
        }else{
		if(document.getElementById("sneep_new_tag_title:"+objecttype)){
			document.getElementById("sneep_new_tag_title:"+objecttype).value="";
		}
                Effect.BlindDown(element);
		switched = sneep_tag(view,objecttype,objectid,'sneep_wait_view', false, filter);

                if(button.tagName.match('INPUT')){
                        button.value = hide;
                }else{
                        button.innerHTML = hide;
                }
        }
}

//This toggles the type of view for the tags
function sneep_tag_view_toggle(button,view1,view2,view_label1,view_label2,object_type,objectid)
{
        var button_text;
	objecttype = object_type.toLowerCase();
	var filter = document.getElementById("sneep_t_filter_flag:"+objecttype).innerHTML;
	var view = document.getElementById("sneep_t_view_flag:"+objecttype);
        var switched=true;

        if(button.tagName.match('INPUT')){
                button_text = button.value;
        }else{
                button_text = button.innerHTML;
        }

        if(button_text.match(view_label1)){
//		alert("view changing to :"+view1+" keeping filter: "+filter);
		switched = sneep_tag(view1,objecttype,objectid,'sneep_wait_view', false, filter,button);
		if(!switched){
			return false;
		}
		view.innerHTML = view1;
                button.innerHTML = view_label2;
        }else{
//		alert("view changing to :"+view2+" keeping filter: "+filter);
		switched = sneep_tag(view2,objecttype,objectid,'sneep_wait_view', false, filter, button);
		if(!switched){
			return false;
		}
		view.innerHTML = view2;
                button.innerHTML = view_label1;
        }	
}
//This toggles the filter on the tag view myTags or allTags
function sneep_tag_filter_toggle(button,filter1,filter2,filter_label1,filter_label2,object_type,objectid)
{
        var button_text;
	objecttype = object_type.toLowerCase();
	var filter = document.getElementById("sneep_t_filter_flag:"+objecttype);
	var view = document.getElementById("sneep_t_view_flag:"+objecttype).innerHTML;
//	var tag_user_span = document.getElementById("sneep_t_current_user");
        var switched=true;
	if(button.tagName.match('INPUT')){
                button_text = button.value;
        }else{
                button_text = button.innerHTML;
        }
	if(button_text.match(filter_label1)){
//		alert("filter changing to :"+filter1+" keeping view: "+view);
		switched = sneep_tag(view,objecttype,objectid,'sneep_wait_filter',false,filter1,button);
//		if(tag_user_span)
//			Effect.Fade(tag_user_span);

		if(!switched){
			return false;
		}
		filter.innerHTML = filter1;
                button.innerHTML = filter_label2;
        }else{
//		alert("filter changing to :"+filter2+" keeping view: "+view);
		switched = sneep_tag(view,objecttype,objectid,'sneep_wait_filter',false,filter2,button);
//		if(tag_user_span)
//			Effect.Appear(tag_user_span);

		if(!switched){
			return false;
		}
		filter.innerHTML = filter2;
                button.innerHTML = filter_label1;
        }
	
}

