/* 
 * 
 * Javascript files are loaded in alphabetic order, hence the "80" 
 * in the filename to force it to load after the other files!
 * 
 * 
*/

function process_comment()
{
	document.getElementById("sneep_c_comment:"+objecttype).innerHTML = xmlHttp.responseText;
	//Need to do what toggle add or toggle edit does here...
//	document.getElementById("sneep_c_add_textarea:"+objecttype).style.display = 'none';
//	document.getElementById("sneep_c_add_save:"+objecttype).style.display = 'none';
//	document.getElementById("sneep_c_add_button:"+objecttype).innerHTML = 'Add';
//	var parent = document.getElementById("sneep_c_add_save:"+objecttype).parentNode;
//	var end_text=get_lastText(parent);
//	if(end_text.data){
//		end_text.deleteData(0,3);
//	}
	sneep_comment_init_comments();
	//Clear the add comment textarea value
        document.getElementById("sneep_new_comment_text:eprint").value = "";
}
function sneep_comment(action, open, object_type, id, wait_id, commentid)
{
	if(wait_id){
		wait_element = document.getElementById(wait_id);
	}
	//globablise the objecttype (objectytype defined in 79_sneep)...
	objecttype = object_type.toLowerCase();
	if(!object_type){
		sneep_comment_eprint(action, open, id, commentid);
	}else{
		object_type = object_type.toLowerCase();
		var cmd = "sneep_comment_"+object_type+"(action, open, id, commentid);";
		eval(cmd);
	}	
}
function sneep_comment_eprint(action, open, eprintid, commentid)
{
	request_script = "comment";
	
	if(eprintid==undefined){
		alert("no eprintid! cannot retrieve comments");
		return false;
	}
	// Is the user logged in? if not they may (depending on the open flag) be able to view but not update
	if(document.getElementById("logged_in")){
		logged_in = true;
	}
	if(open==1 && !logged_in){
		log_in_to_edit(request_script);
	}else if(!open && !logged_in){
		log_in_to_view(request_script);
		return false;
	}

	var url = get_url(open, action, logged_in, eprintid, commentid, 'EPrint');
	if(!url){
		alert("I could not retrieve the url of the script that I'm meant to call");
		return false;
	}
	var params = get_params(action, commentid, request_script);
	if(params != -1 ){
		loadXMLDoc(url,params);
	}else{
		return false;
	}
}
//Not sure whether there needs to be a separate sneep_comment_x for each object...
function sneep_comment_document(action, open, eprintid, commentid)
{
	request_script = "comment";
	
	if(eprintid==undefined){
		alert("no eprintid! cannot retrieve comments");
		return false;
	}
	// Is the user logged in? if not they may (depending on the open flag) be able to view but not update
	if(document.getElementById("logged_in")){
		logged_in = true;
	}
	if(open==1 && !logged_in){
		log_in_to_edit(request_script);
	}else if(!open && !logged_in){
		log_in_to_view(request_script);
		return false;
	}

	var url = get_url(open, action, logged_in, eprintid, commentid, 'Document');
	if(!url){
		alert("I could not retrieve the url of the script that I'm meant to call");
		return false;
	}
	var params = get_params(action, commentid, request_script);
	if(params != -1 ){
		loadXMLDoc(url,params);
	}else{
		return false;
	}
}

function SneepCommentAdd(objecttype, objectid, wait_id)
{
	sneep_comment( 'Add', 0, objecttype, objectid, wait_id);
}
function SneepCommentUpdate(objecttype, objectid, commentid, wait_id)
{
	sneep_comment( 'Update', 0, objecttype, objectid, wait_id, commentid);
}
function SneepCommentDelete(objecttype, objectid, commentid, wait_id)
{
	var r = confirm("Are you sure you want to delete this comment?");
	if(r){
		sneep_comment( 'Delete', 0, objecttype, objectid, wait_id, commentid);
	}else{
		return false;
	}
}

var browser;
var b_version;
var version;

// Sneep init function is snaffled into the onload via cfg.d/dynamic_template.pl 
// It also moves buttons up a pixel in opera 
function sneep_comment_init()
{
	var n;
	if(document.getElementById("logged_in")){
		logged_in = true;
	}
	for(n in objects){
		if(!document.getElementById('sneep_c_main:'+objects[n])){continue;}
		var comments_box = document.getElementById('sneep_c_main:'+objects[n]);
		for(var i=0; i<comments_box.childNodes.length; i++){
			if(comments_box.childNodes[i].nodeType == 1){
				var element = comments_box.childNodes[i];
				if(element.tagName.match("FORM")){
					var inputs = element.getElementsByTagName("input");
					if(!logged_in){
						for(j=0; j<inputs.length; j++){
							if(inputs[j].type.match("submit")){
								inputs[j].style.display = 'none';
						//		var parent = inputs[j].parentNode;
						//		var end_text=get_lastText(parent);
						//		if(end_text.data){
						//			end_text.deleteData(0,3);
						//		}
							}
						}
						var divs = element.getElementsByTagName("div");
						for(j=0; j<divs.length; j++){
							if(divs[j].firstChild.tagName.match("TEXTAREA")){
								divs[j].style.display = 'none';
							}
						}
					}
				}
			}
		}
		comments_box.style.display = 'none';
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

// This init function is called after the sneep_comments returns the response 
// (comments) and appends them to the sneep_c_comment div
// It does the same kind of jobs as sneep_comment_init(); except it doesn't need a list of 
// element ids cos it is well clever (until someone changes the render_HTML method in Comment.pm)
function sneep_comment_init_comments(){
	var comments = document.getElementById('sneep_c_list:'+objecttype);
//	if(!comments) return false;
	for(var i=0; i<comments.childNodes.length; i++){
		if(comments.childNodes[i].nodeType == 1){
			var li = comments.childNodes[i];
			var inputs = li.getElementsByTagName("input");
			for(var j=0; j<inputs.length; j++){
				if(inputs[j].value == 'Save'){
					inputs[j].style.display = 'none';
					var parent = inputs[j].parentNode;
					var end_text=get_lastText(parent);
					if(end_text.data){
						end_text.deleteData(0,3);
					}
				}
			}
			var spans = li.getElementsByTagName("span");
			for(j=0; j<spans.length; j++){
				if(spans[j].nodeType == 1){
					if(spans[j].firstChild){
						if(spans[j].firstChild.tagName == "TEXTAREA"){
							spans[j].style.display = 'none';
						}
					}
				}
			}

		        if(browser == "Opera"){
		                var buttons = document.getElementsByTagName("button");
		                for(var j=0; j<buttons.length; j++){
		                        buttons[j].style.position = 'relative';
		                        buttons[j].style.top = '1px';
		                }
	        	}	
		}
	}
}

//This toggles the whole comment box from a link on the abstract page
function sneep_comment_toggle(element_id,button,show,hide)
{
        var element = document.getElementById(element_id);
        var button_text;
	var sf = document.getElementById("sneep_c_status_flag:"+objecttype);

        if(button.tagName.match('INPUT')){
                button_text = button.value;
        }else{
                button_text = button.innerHTML;
        }

        if(button_text.match(hide)){
//                Effect.BlindUp(element, {afterFinish: revertLayout});
                Effect.BlindUp(element);
                if(button.tagName.match('INPUT')){
                        button.value = show;
                }else{
                        button.innerHTML = show;
                }
		// set invisible status flag, this will either be 0 or the float value
		sf.innerHTML = "0";
        }else{
//                Effect.BlindDown(element, {afterFinish: columnLayout});
                Effect.BlindDown(element);
                if(button.tagName.match('INPUT')){
                        button.value = hide;
                }else{
                        button.innerHTML = hide;
                }
		sf.innerHTML = "left";
        }
}


//This toggles the add comment textarea
function sneep_comment_toggle_add(element_id,button,show,hide)
{
        var element = document.getElementById(element_id);
        var comment_add_save =  document.getElementById('sneep_c_add_save:'+objecttype);
	var save_parent = comment_add_save.parentNode;
	var save_parent = document.getElementById('sneep_c_add:'+objecttype);
	var end_text=get_lastText(save_parent); //This is the divider that is hanging off the end of the tools 

        var button_text;
        if(button.tagName.match('INPUT')){
                button_text = button.value;
        }else{
                button_text = button.innerHTML;
        }

        if(button_text.match(hide)){
                Effect.SlideUp(element);
                if(button.tagName.match('INPUT')){
                        button.value = show;
                }else{
                        button.innerHTML = show;
                }
		end_text.deleteData(0,3);
                Effect.Fade(comment_add_save);
        }else{
		element.getElementsByTagName("textarea")[0].value='';

                Effect.SlideDown(element, {afterFinish: focusAfterAppear});
                if(button.tagName.match('INPUT')){
                        button.value = hide;
                }else{
                        button.innerHTML = hide;
                }
		// What we need is a config collecting init function so that the JS has access to all the stuff in sneep.xml
		// cos it beats doing this...
		end_text.insertData(0," | ");                  
		Effect.Appear(comment_add_save);
        }
}

// This toggles the individual comment textareas used for editinf in a user match condition (or admin).
// Note that this depends on no one changing the element ids set in EPrints::Plugin::Comment->render_HTML();
function sneep_comment_toggle_edit(commentid,button,show,hide)
{
        //these fellas stay hidden
        var form = document.getElementById('sneep_c_edit_span_'+commentid+":"+objecttype);
        var text = document.getElementById('sneep_c_text_'+commentid+":"+objecttype);
        //this one is toggled
        var comment_save =  document.getElementById('sneep_c_edit_save_'+commentid+":"+objecttype);
	var save_parent = comment_save.parentNode;
	var end_text=get_lastText(save_parent); //This is the fdivider that is hanging off the end of the tools 

        //comment is the whole comment
        var comment = document.getElementById('sneep_c_text_p_'+commentid+":"+objecttype);

        //comment_tools are the edit delete save buttons
        var comment_tools = document.getElementById('sneep_c_tools_'+commentid+":"+objecttype);

        //clone our hidden stuff so we can swap it in and out of the comment div
        form_clone = form.cloneNode(true);
        text_clone = text.cloneNode(true);

        var button_text;
        if(button.tagName.match('INPUT')){
                button_text = button.value;
        }else{
                button_text = button.innerHTML;
        }

        if(button_text.match(hide)){
                if(button.tagName.match('INPUT')){
                        button.value = show;
                }else{
                        button.innerHTML = show;
                }
                button_text = show;
                comment.innerHTML = '';
                comment.appendChild(text_clone);
                Effect.Appear(text_clone);
		end_text.deleteData(0,3);
                Effect.Fade(comment_save);
        }else{
                if(button.tagName.match('INPUT')){
                        button.value = hide;
                }else{
                        button.innerHTML = hide;
                }
                comment.innerHTML = '';
                //get textarea from form_clone (there is only one)
                var textarea = form_clone.getElementsByTagName('textarea')[0];
                textarea.value = text_clone.innerHTML;
                comment.appendChild(form_clone);
                Effect.Appear(form_clone, {afterFinish: focusAfterAppear});
		end_text.insertData(0," | ");                  
                Effect.Appear(comment_save);
        }
}

