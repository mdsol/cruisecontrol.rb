// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function toggle_section(section) {
  if (section.className == "section_open")
    section.className = "section_closed"
  else
    section.className = "section_open"
}

function disableBuildNowButton(button) {
  button.className='build_button_disabled';
  button.disabled = true;
}







var cX = 0; var cY = 0; var rX = 0; var rY = 0;

function UpdateCursorPosition(e){ 
	cX = e.pageX; 
	cY = e.pageY;
}

function UpdateCursorPositionDocAll(e){ 
	cX = event.clientX; 
	cY = event.clientY;
}

if(document.all) { 
	document.onmousemove = UpdateCursorPositionDocAll; 
} else { 
	document.onmousemove = UpdateCursorPosition; 
}

function AssignPosition(d, pX, pY) {
	
	if(self.pageYOffset) {
		rX = self.pageXOffset;
		rY = self.pageYOffset;
  }
	else if(document.documentElement && document.documentElement.scrollTop) {
		rX = document.documentElement.scrollLeft;
		rY = document.documentElement.scrollTop;
  }
	else if(document.body) {
		rX = document.body.scrollLeft;
		rY = document.body.scrollTop;
  }
	if(document.all) {
		cX += rX; 
		cY += rY;
	}
	
	if(cY < 100){
		/*top display where raider name link is on top menu
     /* removed cY cord in d.style.top reinstate like this cY+pY */
		//pX = 300;
		//pY = 20;
		//d.style.left = (cX-pX) + "px";
		//d.style.top = (30) + "px";
		
    d.style.left = (420) + "px";
    d.style.top = (0) + "px";
		
	} else {
		/*Bottom display where room of the day is
     /* removed cY cord in d.style.top reinstate like this cY+pY */
		pX = 100;
		pY = -120;
		d.style.left = (cX-pX) + "px";
		d.style.top = (305) + "px";
	}
  
}


function HideTipTop(phantomline) {
	if(phantomline.length < 1) { return; }
	document.getElementById(phantomline).style.display = "none";
	document.getElementById(phantomline).style.top = "";
}

function ShowTipTop(phantomline) {
	if(phantomline.length < 1) { return; }
	var phantomline = document.getElementById(phantomline);  
	AssignPosition(phantomline);
	phantomline.style.display = "block";
}