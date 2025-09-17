/* A Bootstrap-based replacement for window.confirm(), with customization options.
	usage :
		confirm_dialog ([title,] message [,choice1, choice2, etc.]);
	where each "choice" object gives a button, according to its attributes :
		- label : text on the button (if empty, the button will not be displayed)
		- class (optional) : CSS class name(s) for the button
		- handler (optional) : callback function called for this choice (if not set, makes a default close button (X) to appear)

	(Note: hence an "empty" object may be used to make the (X) button appear. Besides, when no choice is set, it appears anyway)
*/

window.confirm_dialog = function (txt, ...choiceObjs) {
	const modal = document.getElementById("modal-confirm-dialog");

	// 1) Texts
	//- title (optional)
	let title;
	if (choiceObjs && choiceObjs.length > 0 && typeof choiceObjs[0] == 'string') {
		title = txt;
		txt = choiceObjs.shift();
	} else {
		title = "";
	}
	const modalTitle = modal.querySelector(".modal-title");
	modalTitle.textContent = title;

	//- main text (required)
	const modalMsg = modal.querySelector(".msg");
	modalMsg.textContent = txt; //note : main text is a mandatory arg

	// 2) default close button (X)
	const buttonClose = modal.querySelector(".btn-close");
	if (choiceObjs && choiceObjs.length > 0) {
		buttonClose.style.display = 'none';
	} else {
		buttonClose.style.display = '';
	}
	 // ... is expected to be activated with a handler-less choice

	// 3) Custom buttons
	const buttons = modal.querySelector(".modal-footer");

	// - prepare button template
	const origBtnTemplate = buttons.querySelector("#button-template");
	origBtnTemplate.style.display = 'none'; // hide original in-place, if not already done
	let buttonTemplate = origBtnTemplate.cloneNode(true);
	buttonTemplate.removeAttribute('id');
	buttonTemplate.style.display = '';

	// - remove old buttons (except template)
	Array.from(buttons.children).forEach(child => {
		if (child !== origBtnTemplate) {
			buttons.removeChild(child);
		}
	});

	let showClose = false;
	choiceObjs.forEach((obj) => {
		if (!obj.handler) showClose = true; // at least one handler-less choice, so show (X) button
		if (!obj.label) return; // no label, no button :-)

		let newButton = buttonTemplate.cloneNode(true);

		//apply label
		newButton.textContent = obj.label;

		// apply CSS class(es)
		if (obj.class) {
			obj.class.split(" ").forEach(cls => {
				if (cls) newButton.classList.add(cls);
			});
		}

		// apply handler
		newButton.addEventListener('click', () => {
			if (obj.handler) obj.handler();

			// hide the dialog anyway, using Bootstrap 5 API
			const bsModal = bootstrap.Modal.getOrCreateInstance(modal);
			bsModal.hide();
		});

		buttons.appendChild(newButton);
		newButton.style.display = '';
	});
	// Show close button if any choice has no handler
	buttonClose.style.display = showClose ? '' : 'none';

	// Show dialog using Bootstrap 5 API
	const bsModal = bootstrap.Modal.getOrCreateInstance(modal);
	bsModal.show();
};

/* A Bootstrap-based replacement for window.alert(), based on confirm_dialog().
	usage :
		alert_dialog ([title,] message);
*/
window.alert_dialog = function (txt1, txt2) {
	if (txt2) {
		window.confirm_dialog(txt1, txt2, {label: "OK", class: "btn-primary"});
	} else {
		window.confirm_dialog(txt1, {label: "OK", class: "btn-primary"});
	}
};
