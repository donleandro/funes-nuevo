/* 
 * 
 * Javascript files are loaded in alphabetic order, hence the "80" 
 * in the filename to force it to load after the other files!
 * 
 * 
*/

/* maybe this would be nice. Need to work out how to get the whole thing into auto.js
tinyMCE.init({
	mode : "exact",
	elements : "sneep_new_note_text:eprint",	
	submit_patch : true,
	strict_loading_mode : true
});

function sneep_toggleEditor(id) {
	var elm = document.getElementById(id);
	if (tinyMCE.getInstanceById(id) == null){
		tinyMCE.execCommand('mceAddControl', false, id);
	}else{
		tinyMCE.execCommand('mceRemoveControl', false, id);
	}
}
*/
function process_note()
{
	document.getElementById("sneep_n_note:"+objecttype).innerHTML = xmlHttp.responseText;
	//Need to do what toggle add or toggle edit does here...
//	document.getElementById("sneep_n_add_textarea:"+objecttype).style.display = 'none';
//	document.getElementById("sneep_n_add_button:"+objecttype).innerHTML = 'Add';
//	var parent = document.getElementById("sneep_n_add_save:"+objecttype).parentNode;
//	if(parent){
//		var end_text=get_lastText(parent);
//		if(end_text.data){ end_text.deleteData(0,3); }
//	}
//	document.getElementById("sneep_n_add_save:"+objecttype).style.display = 'none';

	sneep_note_init_notes();
        document.getElementById("sneep_new_note_text:eprint").value = "";
        document.getElementById("sneep_new_note_title:eprint").value = "";
}
function sneep_note(action, object_type, id, wait_id, noteid)
{
	if(wait_id){
		wait_element = document.getElementById(wait_id);
	}
	//globablise the objecttype (objectytype defined in 79_sneep)...
	objecttype = object_type.toLowerCase();
	if(!object_type){
		sneep_note_eprint(action, id, noteid);
	}else{
		object_type = object_type.toLowerCase();
		var cmd = "sneep_note_"+object_type+"(action, id, noteid);";
		eval(cmd);
	}	
}
function sneep_note_eprint(action, eprintid, noteid)
{
	request_script = "note";
	if(eprintid==undefined){
		alert("no eprintid! cannot retrieve notes");
		return false;
	}
	// Is the user logged in? if not they may (depending on the open flag) be able to view but not update
	if(document.getElementById("logged_in")){
		logged_in = true;
	}
	if(!logged_in){
		log_in_to_view(request_script);
		return false;
	}
	var open = 0;
	var url = get_url(open, action, logged_in, eprintid, noteid, 'EPrint');

	if(!url){
		alert("I could not retrieve the url of the script that I'm meant to call");
		return false;
	}
	var params = get_params(action, noteid, request_script);
	if(params != -1 ){
		loadXMLDoc(url,params);
	}else{
		return false;
	}
}
function sneep_note_document(action, eprintid, noteid)
{
	request_script = "note";
	if(eprintid==undefined){
		alert("no eprintid! cannot retrieve notes");
		return false;
	}
	// Is the user logged in? if not they may (depending on the open flag) be able to view but not update
	if(document.getElementById("logged_in")){
		logged_in = true;
	}
	if(!logged_in){
		log_in_to_view(request_script);
		return false;
	}
	var open = 0;
	var url = get_url(open, action, logged_in, eprintid, noteid, 'Document');

	if(!url){
		alert("I could not retrieve the url of the script that I'm meant to call");
		return false;
	}
	var params = get_params(action, noteid, request_script);
	if(params != -1 ){
		loadXMLDoc(url,params);
	}else{
		return false;
	}
}


function SneepNoteAdd(objecttype, objectid, wait_id)
{
	sneep_note( 'Add', objecttype, objectid, wait_id);
}
function SneepNoteUpdate(objecttype, objectid, noteid, wait_id)
{
	sneep_note( 'Update', objecttype, objectid, wait_id, noteid);
}
function SneepNoteDelete(objecttype, objectid, noteid, wait_id)
{
	var r = confirm("Are you sure you want to delete this note?");
	if(r){
		sneep_note( 'Delete', objecttype, objectid, wait_id, noteid);
	}else{
		return false;
	}
}

var browser;
var b_version;
var version;

// Sneep init function is snaffled into the onload via cfg.d/dynamic_template.pl 
// Hides elements passed to via thingsToHide which should be a colon separated list of elementids
// It also moves buttons up a pixel in opera cos it is annoying... and IE..? hold on [pause] IE renders them nice and even...
function sneep_note_init()
{
	var n;
	if(document.getElementById("logged_in")){
		logged_in = true;
	}
	for(n in objects){
		if(!document.getElementById('sneep_n_main:'+objects[n])){continue;}
		var notes_box = document.getElementById('sneep_n_main:'+objects[n]);
		for(var i=0; i<notes_box.childNodes.length; i++){
			if(notes_box.childNodes[i].nodeType == 1){
//				var element = notes_box.childNodes[i];
				var element = notes_box;
				if(element.tagName.match("FORM")){
					var inputs = element.getElementsByTagName("input");
					for(j=0; j<inputs.length; j++){
						if(inputs[j].type.match("submit")){
							inputs[j].style.display = 'none';
					//		var parent = inputs[j].parentNode;
					//		if(parent){
					//			var end_text=get_lastText(parent);
					//			end_text.deleteData(0,3);
					//		}
						}
					}
					var divs = element.getElementsByTagName("div");
					for(j=0; j<divs.length; j++){
						if(divs[j].firstChild){
							if(divs[j].firstChild.id.match("/sneep_new/")){
								divs[j].style.display = 'none';
							}
						}
					}
				}
			}
		}
		notes_box.style.display = 'none';
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

// This init function is called after the sneep_notes returns the response 
// (notes) and appends them to the sneep_n_note div
// It does the same kind of jobs as sneep_note_init(); except it doesn't need a list of 
// element ids cos it is well clever (until someone changes the note_to_HTML method in SneepComment.pm)
function sneep_note_init_notes(){
	if(!document.getElementById('sneep_n_list:'+objecttype)){
		return false;
	}
	var notes = document.getElementById('sneep_n_list:'+objecttype);
	if(!notes) return false;
	for(var i=0; i<notes.childNodes.length; i++){
		if(notes.childNodes[i].nodeType == 1){
			var li = notes.childNodes[i];
			var inputs = li.getElementsByTagName("input");
			for(var j=0; j<inputs.length; j++){
				if(inputs[j].value == 'Save'){
					inputs[j].style.display = 'none';
					var parent = inputs[j].parentNode;
					if(parent){
						var end_text=get_lastText(parent);
						end_text.deleteData(0,3);
					}

				}
			}
			var spans = li.getElementsByTagName("span");
			for(j=0; j<spans.length; j++){
				if(spans[j].nodeType == 1 && spans[j].id.match(/edit_span/)){
					spans[j].style.display = 'none';
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

//This toggles the whole note box from a link on the abstract page
function sneep_note_toggle(element_id,button,show,hide)
{
        var element = document.getElementById(element_id);
        var button_text;
	var sf = document.getElementById("sneep_n_status_flag:"+objecttype);

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
		sf.innerHTML = "0";
        }else{
//                Effect.BlindDown(element, {afterFinish: columnLayout});
                Effect.BlindDown(element);
                if(button.tagName.match('INPUT')){
                        button.value = hide;
                }else{
                        button.innerHTML = hide;
                }
		sf.innerHTML = "right";
        }
}


//This toggles the add note textarea
function sneep_note_toggle_add(element_id,button,show,hide)
{
        var element = document.getElementById(element_id);
        var note_add_save =  document.getElementById('sneep_n_add_save:'+objecttype);

	var save_parent = note_add_save.parentNode;
	var end_text=get_lastText(save_parent); //This is the fdivider that is hanging off the end of the tools 

        var button_text;
        if(button.tagName.match('INPUT')){
                button_text = button.value;
        }else{
                button_text = button.innerHTML;
        }

        if(button_text.match(hide)){
                Effect.BlindUp(element);
                if(button.tagName.match('INPUT')){
                        button.value = show;
                }else{
                        button.innerHTML = show;
                }
		end_text.deleteData(0,3);
                Effect.Fade(note_add_save);
        }else{
		element.getElementsByTagName("textarea")[0].value='';
		element.getElementsByTagName("input")[0].value='';

                Effect.BlindDown(element, {afterFinish: focusAfterAppear});
                if(button.tagName.match('INPUT')){
                        button.value = hide;
                }else{
                        button.innerHTML = hide;
                }
		// What we need is a config collecting init function so that the JS has access to all the stuff in sneep.xml
		// cos it beats doing this...
		end_text.insertData(0," | ");                  
		Effect.Appear(note_add_save);
        }
}

// This toggles the individual note textareas used for editinf in a user match condition (or admin).
// Note that this depends on no one changing the element ids set in EPrints::Plugin::SneepComment->note_to_HTML();
function sneep_note_toggle_edit(noteid,button,show,hide)
{
        //these fellas stay hidden
        var form = document.getElementById('sneep_n_edit_span_'+noteid+':'+objecttype);
        var text = document.getElementById('sneep_n_text_'+noteid+':'+objecttype);
        //this one is toggled
        var note_save =  document.getElementById('sneep_n_edit_save_'+noteid+':'+objecttype);
	var save_parent = note_save.parentNode;
	var end_text=get_lastText(save_parent); //This is the fdivider that is hanging off the end of the tools 

        //note is the whole note
        var note = document.getElementById('sneep_n_text_p_'+noteid+':'+objecttype);

        //note_tools are the edit delete save buttons
        var note_tools = document.getElementById('sneep_n_tools_'+noteid+':'+objecttype);

        //clone our hidden stuff so we can swap it in and out of the note div
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
                note.innerHTML = '';
                note.appendChild(text_clone);
                Effect.Appear(text_clone);
		end_text.deleteData(0,3);
                Effect.Fade(note_save);
        }else{
                if(button.tagName.match('INPUT')){
                        button.value = hide;
                }else{
                        button.innerHTML = hide;
                }
                note.innerHTML = '';
                //get textarea from form_clone (there is only one)
                var textarea = form_clone.getElementsByTagName('textarea')[0];
                textarea.value = text_clone.innerHTML;
                note.appendChild(form_clone);
                Effect.Appear(form_clone, {afterFinish: focusAfterAppear});
		end_text.insertData(0," | ");                  
                Effect.Appear(note_save);
        }
}
