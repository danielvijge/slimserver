var Utils = function(){
	return {
		init : function(){
			if (el = Ext.get('content'))
				if (el && el.hasClass('scrollingPanel')) {
					Ext.EventManager.onWindowResize(Utils.resizeContent);
					Ext.EventManager.onDocumentReady(Utils.resizeContent);
				}

			// add highlighter class
			this.addBrowseMouseOver();

		},

		addBrowseMouseOver: function(){
			Ext.addBehaviors({
				'.selectorMarker@mouseover': function(ev, target){
					if (target.tagName != 'DIV' || !Ext.get(target).hasClass('selectorMarker'))
						return;

					// remove highlighting from the other DIVs
					items = Ext.DomQuery.select('div.mouseOver');
					for(var i = 0; i < items.length; i++) {
						el = Ext.get(items[i].id);
						if (el) {
							el.replaceClass('mouseOver', 'selectorMarker');
						
							if (controls = Ext.DomQuery.selectNode('span.browsedbControls', el.dom)) {
								Ext.get(controls).hide();
							}
						}
					}

					el = Ext.get(target);
					if (el) {
						el.replaceClass('selectorMarker', 'mouseOver');
						
						if (controls = Ext.DomQuery.selectNode('span.browsedbControls', el.dom)) {
							Ext.get(controls).show();
						}
					}
				}
			});
		},

		resizeContent : function(){
			infoHeight = 0;
			if (el = Ext.get('infoTab'))
				infoHeight = el.getHeight();

			el = Ext.get('content');
			if (el && el.hasClass('scrollingPanel')) {
				el.setHeight(Ext.fly(document.body).getHeight() - el.getTop() - infoHeight);
			}
		}

	};
}();
Ext.EventManager.onDocumentReady(Utils.init, Utils, true);


// Extensions to ExtJS classes
Slim = {};

// graphical button, defined in three element sprite for normal, mouseover, pressed
Slim.Button = function(renderTo, config){
	// I've given up on IE6 - don't animate those buttons :-(
	if (Ext.isIE && !Ext.isIE7)
		this.template = new Ext.Template('<img src="html/images/spacer.gif" height="{0}" width="{1}">');
	else
		this.template = new Ext.Template('<span><button><img src="html/images/spacer.gif"></button></span>');

	Slim.Button.superclass.constructor.call(this, renderTo, config);	
};

Ext.extend(Slim.Button, Ext.Button, {
	render: function(renderTo){
		if (Ext.isIE && !Ext.isIE7) {
			this.el = Ext.get(renderTo);
			this.el.setStyle({
				'background': 'url(' + this.icon + ') no-repeat 0px 0px'
			});
			this.el.on({
				'click': {
					fn: function(e){
						if (this.handler)
							this.handler.call(this.scope || this, this, e)
					},
					scope: this
				}
			});

			this.template.append(renderTo, [this.height, this.width]);
		}
		else {
			Slim.Button.superclass.render.call(this, renderTo);
			var btnFrm = this.el.child("button:first");
			btnFrm.setStyle({
				'width': this.width + 'px',
				'height': this.height + 'px',
				'padding': '0',
				'margin': '0'
			});
		}
	},

	onClick : function(e){
		if(e){
			e.preventDefault();
		}
		if(e.button != 0){
			return;
		}
		if(!this.disabled){
			if(this.enableToggle){
				this.toggle();
			}
			if(this.menu && !this.menu.isVisible()){
				this.menu.show(this.el, this.menuAlign);
			}
			this.fireEvent("click", this, e);
			if(this.handler){
				this.onMouseUp();
				this.handler.call(this.scope || this, this, e);
			}
		}
	},
   
	onMouseOver: function(e){
		if(!this.disabled && (myEl = this.el.child("button:first"))) {
			myEl.setStyle('background', 'url(' + this.icon + ') no-repeat 0px -' + String(this.height) + 'px');
			this.fireEvent('mouseover', this, e);
		}
	},

	onMouseOut : function(e){
		if(!e.within(this.el,  true) && (myEl = this.el.child("button:first"))) {
			myEl.setStyle('background', 'url(' + this.icon + ') no-repeat 0px 0px');
			this.fireEvent('mouseout', this, e);
		}
	},

	onFocus : function(e){
		if(!this.disabled && (myEl = this.el.child("button:first"))) {
			myEl.setStyle('background', 'url(' + this.icon + ') no-repeat 0px -' + String(this.height) + 'px');
		}
	},

	onBlur : function(e){
		if (myEl = this.el.child('button:first')) {
			myEl.setStyle('background', 'url(' + this.icon + ') no-repeat 0px 0px');
		}
		else if (Ext.isIE && !Ext.isIE7) {
			this.el.setStyle('background', 'url(' + this.icon + ') no-repeat 0px 0px');
		}
	},

	onMouseDown : function(e){
		if(!this.disabled && e.button == 0 && (myEl = this.el.child("button:first"))) {
			myEl.setStyle('background', 'url(' + this.icon + ') no-repeat 0px -' + String(this.height * 2) + 'px');
		}
	},

	onMouseUp : function(e){
		if (myEl = this.el.child('button:first')) {
			myEl.setStyle('background', 'url(' + this.icon + ') no-repeat 0px 0px');
		}
	}
});

// some legacy scripts

// update the status if the Player is available
function refreshStatus() {
	try { Player.getUpdate() }
	catch(e) {}
}