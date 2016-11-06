/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

package scratch {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import blocks.Block;
	import blocks.BlockArg;
	
	import cc.makeblock.mbot.uiwidgets.lightSetter.LightSetterFrame;
	import cc.makeblock.menu.MenuUtil;
	
	import extensions.ArduinoManager;
	
	import filters.FilterPack;
	
	import interpreter.RobotHelper;
	
	import org.aswing.event.AWEvent;
	
	import sound.SoundBank;
	
	import translation.Translator;
	
	import ui.ProcedureSpecEditor;
	
	import uiwidgets.CursorTool;
	import uiwidgets.DialogBox;
	import uiwidgets.Menu;
	import uiwidgets.Piano;
	
	import util.DragClient;

public class BlockMenus implements DragClient {

	private var app:MBlock;
	private var startX:Number;
	private var startY:Number;
	private var block:Block;
	private var blockArg:BlockArg; // null if menu is invoked on a block

	private static const basicMathOps:Array = ['+', '-', '*', '/'];
	private static const comparisonOps:Array = ['<', '=', '>'];

	public static function BlockMenuHandler(evt:MouseEvent, block:Block, blockArg:BlockArg = null, menuName:String = null):void {
		var menuHandler:BlockMenus = new BlockMenus(block, blockArg);
		var op:String = block.op;
		if (menuName == null) { // menu gesture on a block (vs. an arg)
			if (op == Specs.GET_LIST) menuName = 'list';
			if (op == Specs.GET_VAR) menuName = 'var';
			if ((op == Specs.PROCEDURE_DEF) || (op == Specs.CALL)) menuName = 'procMenu';
			if ((op == 'broadcast:') || (op == 'doBroadcastAndWait') || (op == 'whenIReceive')) menuName = 'broadcastInfoMenu';
			if ((basicMathOps.indexOf(op)) > -1) { menuHandler.changeOpMenu(evt, basicMathOps); return; }
			if ((comparisonOps.indexOf(op)) > -1) { menuHandler.changeOpMenu(evt, comparisonOps); return; }
			if (menuName == null) { menuHandler.genericBlockMenu(evt); return; }
		}
		
		if (menuName == 'drawFace'){
			menuHandler.drawFace(evt);
			return;
		}
		
		if (op.indexOf('.') > -1) {
			menuHandler.extensionMenu(evt, menuName);
			return;
		}
		if (menuName == 'attribute') menuHandler.attributeMenu(evt);
		if (menuName == 'backdrop') menuHandler.backdropMenu(evt);
		if (menuName == 'booleanSensor') menuHandler.booleanSensorMenu(evt);
		if (menuName == 'broadcast') menuHandler.broadcastMenu(evt);
		if (menuName == 'broadcastInfoMenu') menuHandler.broadcastInfoMenu(evt);
		if (menuName == 'colorPicker') menuHandler.colorPicker(evt);
		if (menuName == 'costume') menuHandler.costumeMenu(evt);
		if (menuName == 'direction') menuHandler.dirMenu(evt);
		if (menuName == 'drum') menuHandler.drumMenu(evt);
		if (menuName == 'effect') menuHandler.effectMenu(evt);
		if (menuName == 'instrument') menuHandler.instrumentMenu(evt);
		if (menuName == 'key') menuHandler.keyMenu(evt);
		if (menuName == 'list') menuHandler.listMenu(evt);
		if (menuName == 'listDeleteItem') menuHandler.listItem(evt, true);
		if (menuName == 'listItem') menuHandler.listItem(evt, false);
		if (menuName == 'mathOp') menuHandler.mathOpMenu(evt);
		if (menuName == 'motorDirection') menuHandler.motorDirectionMenu(evt);
		//if (menuName == 'note') menuHandler.noteMenu(evt);
		if (menuName == 'note') menuHandler.notePicker(evt);
		if (menuName == 'procMenu') menuHandler.procMenu(evt);
		if (menuName == 'rotationStyle') menuHandler.rotationStyleMenu(evt);
		if (menuName == 'scrollAlign') menuHandler.scrollAlignMenu(evt);
		if (menuName == 'sensor') menuHandler.sensorMenu(evt);
		if (menuName == 'sound') menuHandler.soundMenu(evt);
		if (menuName == 'spriteOnly') menuHandler.spriteMenu(evt, false, false, false, true);
		var m:Menu;
		if (menuName == 'spriteOrMouse') {
			m = menuHandler.spriteMenu(evt, true, false, false, true);
			m.addItem("random horizontal point", "rhp");
			m.addItem("random vertical point", "rvp");
			m.addItem("random stage point", "rsp");
			menuHandler.showMenu(m);
		}
		if (menuName == 'spriteOrStage') menuHandler.spriteMenu(evt, false, false, true, true);
		if (menuName == 'touching'){
			m = menuHandler.spriteMenu(evt, true, true, false, false);
			m.addItem("top edge");
			m.addItem("right edge");
			m.addItem("bottom edge");
			m.addItem("left edge");
			menuHandler.showMenu(m);
		}
		if (menuName == 'stageOrThis') menuHandler.stageOrThisSpriteMenu(evt);
		if (menuName == 'stop') menuHandler.stopMenu(evt);
		if (menuName == 'timeAndDate') menuHandler.timeAndDateMenu(evt);
		if (menuName == 'triggerSensor') menuHandler.triggerSensorMenu(evt);
		if (menuName == 'var') menuHandler.varMenu(evt);
		if (menuName == 'videoMotionType') menuHandler.videoMotionTypeMenu(evt);
		if (menuName == 'videoState') menuHandler.videoStateMenu(evt);
	}
	
	public static function strings():Array {
		// Exercises all the menus to cause their items to be recorded.
		// Return a list of additional strings (e.g. from the key menu).
		var events:Array = [new MouseEvent('dummy'), new MouseEvent('shift-dummy')];
		events[1].shiftKey = true;
		var handler:BlockMenus = new BlockMenus(new Block('dummy'), null);
		for each (var evt:MouseEvent in events) {
			handler.attributeMenu(evt);
			handler.backdropMenu(evt);
			handler.booleanSensorMenu(evt);
			handler.broadcastMenu(evt);
			handler.broadcastInfoMenu(evt);
			handler.costumeMenu(evt);
			handler.dirMenu(evt);
			handler.drumMenu(evt);
			handler.effectMenu(evt);
			handler.genericBlockMenu(evt);
			handler.instrumentMenu(evt);
			handler.listMenu(evt);
			handler.listItem(evt, true);
			handler.listItem(evt, false);
			handler.mathOpMenu(evt);
			handler.motorDirectionMenu(evt);
			handler.procMenu(evt);
			handler.rotationStyleMenu(evt);
//			handler.scrollAlignMenu(evt);
			handler.sensorMenu(evt);
			handler.soundMenu(evt);
			handler.spriteMenu(evt, false, false, false, true);
			handler.spriteMenu(evt, true, false, false, false);
			handler.spriteMenu(evt, false, false, true, false);
			handler.spriteMenu(evt, true, true, false, false);
			handler.stageOrThisSpriteMenu(evt);
			handler.stopMenu(evt);
			handler.timeAndDateMenu(evt);
			handler.triggerSensorMenu(evt);
			handler.varMenu(evt);
			handler.videoMotionTypeMenu(evt);
			handler.videoStateMenu(evt);
		}
		return [
			'up arrow', 'down arrow', 'right arrow', 'left arrow', 'space',
			'backdrop #', 'backdrop name', 'volume', 'OK', 'Cancel',
			'Edit Block', 'Rename' , 'New name', 'Delete', 'Broadcast', 'Message Name',
			'delete variable', 'rename variable',
			'Low C', 'Middle C', 'High C',
		];
	}

	public function BlockMenus(block:Block, blockArg:BlockArg) {
		app = MBlock.app;
		this.startX = app.mouseX;
		this.startY = app.mouseY;
		this.blockArg = blockArg;
		this.block = block;
	}

	static private function isGeneric(s:String):Boolean {
		return ['duplicate', 'delete', 'add comment'].indexOf(s) > -1;
	}
	public static function shouldTranslateItemForMenu(item:String, menuName:String):Boolean {
		// Return true if the given item from the given menu parameter slot should be
		// translated. This mechanism prevents translating proper names such as sprite,
		// costume, or variable names.
		switch (menuName) {
		case 'attribute':
			var attributes:Array = [
				'x position', 'y position', 'direction', 'costume #', 'costume name', 'size', 'volume',
				'backdrop #', 'backdrop name', 'volume'];
			return attributes.indexOf(item) > -1;
		case 'backdrop':
			return ['next backdrop', 'previous backdrop'].indexOf(item) > -1;
		case 'broadcast':
			return ['new message...'].indexOf(item) > -1;
		case 'costume':
			return false;
		case 'list':
			if (isGeneric(item)) return true;
			return ['delete list'].indexOf(item) > -1;
		case 'sound':
			return ['record...'].indexOf(item) > -1;
		case 'spriteOnly':
		case 'spriteOrMouse':
		case 'spriteOrStage':
		case 'touching':
			return false; // handled directly by menu code
		case 'var':
			if (isGeneric(item)) return true;
			return ['delete variable', 'rename variable'].indexOf(item) > -1;
		}
		return true;
	}

	private function showMenu(m:*):void {
		var p:Point;
		if(m is Menu){
			m.color = block.base.color;
			m.itemHeight = 22;
			if (blockArg) {
				p = blockArg.localToGlobal(new Point(0, 0));
				m.showOnStage(app.stage, p.x - 9, p.y + blockArg.height);
			} else {
				m.showOnStage(app.stage);
			}
		}else if(m is NativeMenu){
			var ctxMenu:NativeMenu = m as NativeMenu;
			MenuUtil.RemoveLastLines(ctxMenu);
			MenuUtil.ChangeLang(ctxMenu);
			if (blockArg) {
				p = blockArg.localToGlobal(new Point(0, 0));
				ctxMenu.display(app.stage, p.x - 9, p.y + blockArg.height);
			} else {
				ctxMenu.display(app.stage, app.stage.mouseX, app.stage.mouseY);
			}
		}
	}

	private function setBlockArg(selection:*):void {
		if (blockArg != null) blockArg.setArgValue(selection);
		MBlock.app.setSaveNeeded();
//		MBlock.app.runtime.checkForGraphicEffects();
	}

	private function attributeMenu(evt:MouseEvent):void {
		var obj:*;
		if (block && block.args[1]) {
			obj = app.stagePane.objNamed(block.args[1].argValue);
		}
		var attributes:Array = ['x position', 'y position', 'direction', 'costume #', 'costume name', 'size', 'volume'];
		if (obj is ScratchStage) attributes = ['backdrop #', 'backdrop name', 'volume'];
		var m:Menu = new Menu(setBlockArg, 'attribute');
		for each (var s:String in attributes) m.addItem(s);
		if (obj is ScratchObj) {
			m.addLine();
			for each (s in obj.varNames().sort()) m.addItem(s);
		}
		showMenu(m);
	}

	private function backdropMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'backdrop');
		for each (var scene:ScratchCostume in app.stageObj().costumes) {
			m.addItem(scene.costumeName);
		}
		if (block && (block.op.indexOf('startScene') > -1)) {
			m.addLine();
			m.addItem('next backdrop');
			m.addItem('previous backdrop');
		}
		showMenu(m);
	}

	static private const sensorNames:Array = [
			'button pressed', 'A connected', 'B connected', 'C connected', 'D connected'];
	private function booleanSensorMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'booleanSensor');
		for each (var s:String in sensorNames) m.addItem(s);
		showMenu(m);
	}

	private function colorPicker(evt:MouseEvent):void {
		app.gh.setDragClient(this, evt);
	}

	private function costumeMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'costume');
		if (app.viewedObj() == null) return;
		for each (var c:ScratchCostume in app.viewedObj().costumes) {
			m.addItem(c.costumeName);
		}
		showMenu(m);
	}

	private function dirMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'direction');
		m.addItem('(90) ' + Translator.map('right'), 90);
		m.addItem('(-90) ' + Translator.map('left'), -90);
		m.addItem('(0) ' + Translator.map('up'), 0);
		m.addItem('(180) ' + Translator.map('down'), 180);
		showMenu(m);
	}

	private function drumMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'drum');
		for (var i:int = 1; i <= SoundBank.drumNames.length; i++) {
			m.addItem('(' + i + ') ' + Translator.map(SoundBank.drumNames[i - 1]), i);
		}
		showMenu(m);
	}

	private function effectMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'effect');
		if (app.viewedObj() == null) return;
		for each (var s:String in FilterPack.filterNames) m.addItem(s);
		showMenu(m);
	}

	private function extensionMenu(evt:MouseEvent, menuName:String):void {
		var items:Array = app.extensionManager.menuItemsFor(block.op, menuName);
		if (app.viewedObj() == null) return;
		var m:Menu = new Menu(setBlockArg);
		for each (var s:String in items) m.addItem(s);
		showMenu(m);
	}

	private function instrumentMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'instrument');
		for (var i:int = 1; i <= SoundBank.instrumentNames.length; i++) {
			m.addItem('(' + i + ') ' + Translator.map(SoundBank.instrumentNames[i - 1]), i);
		}
		showMenu(m);
	}

	static private const namedKeys:Array = ['up arrow', 'down arrow', 'right arrow', 'left arrow', 'space'];
	private function keyMenu(evt:MouseEvent):void {
		var ch:int;
		var m:Menu = new Menu(setBlockArg, 'key');
		for each (var s:String in namedKeys) m.addItem(s);
		for (ch = 97; ch < 123; ch++) m.addItem(String.fromCharCode(ch)); // a-z
		for (ch = 48; ch < 58; ch++) m.addItem(String.fromCharCode(ch)); // 0-9
		showMenu(m);
	}

	private function listItem(evt:MouseEvent, forDelete:Boolean):void {
		var m:Menu = new Menu(setBlockArg, 'listItem');
		m.addItem('1');
		m.addItem('last');
		if (forDelete) {
			m.addLine();
			m.addItem('all');
		} else {
			m.addItem('random');
		}
		showMenu(m);
	}

	static private const mathOpMenu_ops:Array = ['abs', 'floor', 'ceiling', 'sqrt', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'ln', 'log', 'e ^', '10 ^'];
	private function mathOpMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'mathOp');
		for each (var op:String in mathOpMenu_ops) m.addItem(op);
		showMenu(m);
	}

	static private const motorDirectionMenu_ops:Array = ['this way', 'that way', 'reverse'];
	private function motorDirectionMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'motorDirection');
		for each (var s:String in motorDirectionMenu_ops) m.addItem(s);
		showMenu(m);
	}
	private function notePicker(evt:MouseEvent):void {
		var piano:Piano = new Piano(block.base.color, app.viewedObj().instrument, setBlockArg);
		if (!isNaN(blockArg.argValue)) {
			piano.selectNote(int(blockArg.argValue));
		}
		var p:Point = blockArg.localToGlobal(new Point(blockArg.width, blockArg.height));
		piano.showOnStage(app.stage, int(p.x - piano.width / 2), p.y);
	}
	static private const notes:Array = [
			['Low C', 48],
			['D', 50],
			['E', 52],
			['F', 53],
			['G', 55],
			['A', 57],
			['B', 59],
			['Middle C', 60],
			['D', 62],
			['E', 64],
			['F', 65],
			['G', 67],
			['A', 69],
			['B', 71],
			['High C', 72],
		];
	private function noteMenu(evt:MouseEvent):void {
		if (!Menu.stringCollectionMode) {
			for (var i:int = 0; i < notes.length; i++) {
				notes[i][0] = '(' + notes[i][1] + ') ' + Translator.map(notes[i][0]); // show key number in menu
			}
			notes.reverse();
		}
		var m:Menu = new Menu(setBlockArg, 'note');
		for each (var pair:Array in notes) {
			m.addItem(pair[0], pair[1]);
		}
		showMenu(m);
	}

	static private const rotationStyles:Array = ['left-right', "don't rotate", 'all around'];
	private function rotationStyleMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'rotationStyle');
		for each (var s:String in rotationStyles) m.addItem(s);
		showMenu(m);
	}

	static private const options:Array = [
			'bottom-left', 'bottom-right', 'middle', 'top-left', 'top-right'];
	private function scrollAlignMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'scrollAlign');
		for each (var s:String in options) m.addItem(s);
		showMenu(m);
	}

	static private const sensorMenu_sensorNames:Array = [
			'slider', 'light', 'sound',
			'resistance-A', 'resistance-B', 'resistance-B', 'resistance-C', 'resistance-D'];
	private function sensorMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'sensor');
		for each (var s:String in sensorMenu_sensorNames) m.addItem(s);
		showMenu(m);
	}

	private function soundMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'sound');
		if (app.viewedObj() == null) return;
		for (var i:int = 0; i < app.viewedObj().sounds.length; i++) {
			m.addItem(app.viewedObj().sounds[i].soundName);
		}
		showMenu(m);
	}

	private function __setSpriteArg(s:*):void
	{
		if (blockArg == null){
			return;
		}
		
		switch(s)
		{
			case "edge":
				blockArg.setArgValue('_edge_', Translator.map('edge'))
				break;
			case "mouse-pointer":
				blockArg.setArgValue('_mouse_', Translator.map('mouse-pointer'));
				break;
			case "myself":
				blockArg.setArgValue('_myself_', Translator.map('myself'));
				break;
			case "Stage":
				blockArg.setArgValue('_stage_', Translator.map('Stage'));
				break;
			case "rhp":
				blockArg.setArgValue('rhp', Translator.map('random horizontal point'));
				break;
			case "rvp":
				blockArg.setArgValue('rvp', Translator.map('random vertical point'));
				break;
			case "rsp":
				blockArg.setArgValue('rsp', Translator.map('random stage point'));
				break;
			case "top edge":
			case "right edge":
			case "bottom edge":
			case "left edge":
				blockArg.setArgValue(s, Translator.map(s));
				break;
			default:
				blockArg.setArgValue(s);
		}
		/*
		if (s == 'edge') blockArg.setArgValue('_edge_', Translator.map('edge'));
		else if (s == 'mouse-pointer') blockArg.setArgValue('_mouse_', Translator.map('mouse-pointer'));
		else if (s == 'myself') blockArg.setArgValue('_myself_', Translator.map('myself'));
		else if (s == 'Stage') blockArg.setArgValue('_stage_', Translator.map('Stage'));
		else blockArg.setArgValue(s);
		*/
		MBlock.app.setSaveNeeded();
	}
	
	private function spriteMenu(evt:MouseEvent, includeMouse:Boolean, includeEdge:Boolean, includeStage:Boolean, includeSelf:Boolean):Menu {
		var spriteNames:Array = [];
		var m:Menu = new Menu(__setSpriteArg, 'sprite');
		if (includeMouse) m.addItem('mouse-pointer', 'mouse-pointer');
		if (includeEdge) m.addItem('edge', 'edge');
		m.addLine();
		if (includeStage) {
			m.addItem(app.stagePane.objName, 'Stage');
			m.addLine();
		}
		if (includeSelf && !app.viewedObj().isStage) {
//			m.addItem('myself', 'myself');
//			m.addLine();
			spriteNames.push(app.viewedObj().objName);
		}
		for each (var sprite:ScratchSprite in app.stagePane.sprites()) {
			if (sprite != app.viewedObj()) spriteNames.push(sprite.objName);
		}
		spriteNames.sort(Array.CASEINSENSITIVE);
		for each (var spriteName:String in spriteNames) {
			m.addItem(spriteName);
		}
		showMenu(m);
		return m;
	}

	private function setStopType(selection:*):void {
		blockArg.setArgValue(selection);
		block.setTerminal((selection == 'all') || (selection == 'this script'));
		block.type = block.isTerminal ? 'f' : ' ';
		MBlock.app.setSaveNeeded();
	}
	private function stopMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setStopType, 'stop');
		m.addItem('all');
		m.addItem('this script');
		m.addItem(app.viewedObj().isStage ? 'other scripts in stage' : 'other scripts in sprite');
		showMenu(m);
	}

	private function stageOrThisSpriteMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'stageOrThis');
		m.addItem(app.stagePane.objName);
		if (!app.viewedObj().isStage) m.addItem('this sprite');
		showMenu(m);
	}

	private function timeAndDateMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'timeAndDate');
		m.addItem('year');
		m.addItem('month');
		m.addItem('date');
		m.addItem('day of week');
		m.addItem('hour');
		m.addItem('minute');
		m.addItem('second');
		showMenu(m);
	}

	private function setTriggerType(s:String):void {
		if ('video motion' == s) app.libraryPart.showVideoButton();
		setBlockArg(s);
	}
	private function triggerSensorMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setTriggerType, 'triggerSensor');
		m.addItem('loudness');
		m.addItem('timer');
		m.addItem('video motion');
		showMenu(m);
	}

	private function videoMotionTypeMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'videoMotion');
		m.addItem('motion');
		m.addItem('direction');
		showMenu(m);
	}

	private function videoStateMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'videoState');
		m.addItem('off');
		m.addItem('on');
		m.addItem('on-flipped');
		showMenu(m);
	}

	// ***** Generic block menu *****

	private function genericBlockMenu(evt:MouseEvent):void {
		if (!block || block.isEmbeddedParameter()) return;
//		var m:Menu = new Menu(null, 'genericBlock');
		var m:NativeMenu = new NativeMenu();
		addGenericBlockItems(m);
		showMenu(m);
	}

	private function addGenericBlockItems(m:NativeMenu):void {
		if (!block) return;
//		m.addLine();
		MenuUtil.AddLine(m);
		if (!isInPalette(block)) {
			if (!block.isProcDef()) {
				if(block.op.indexOf("runArduino")>-1){
					ArduinoManager.sharedManager().mainX = block.x;
					ArduinoManager.sharedManager().mainY = block.y;
					if(!app.stageIsArduino){
						MenuUtil.AddItem(m, 'upload to arduino');
//						m.addItem('upload to arduino',app.scriptsPart.showArduinoCode);
					}
				}
				MenuUtil.AddItem(m, 'duplicate');
				MenuUtil.AddItem(m, 'delete');
				MenuUtil.AddLine(m);
				/*
				m.addItem('duplicate', duplicateStack);
				m.addItem('delete', block.deleteStack);
				m.addLine();
				*/
			}
//			m.addItem('add comment', block.addComment);
			MenuUtil.AddItem(m, 'add comment');
		}
		//m.addItem('help', block.showHelp);
//		m.addLine();
		MenuUtil.AddLine(m);
		m.addEventListener(Event.SELECT, __onSelect);
	}
	
	private function __onSelect(evt:Event):void
	{
		switch(evt.target.name)
		{
			case "upload to arduino":
				app.scriptsPart.showArduinoCode();
				break;
			case "duplicate":
				/*
				if (block.isProcDef()) return; // don't duplicate procedure definition
				var newStack:Block = BlockIO.stringToStack(BlockIO.stackToString(block), false);
				newStack.x = block.x + 20;
				newStack.y = block.y + 20;
				block.parent.addChild(newStack);
				*/
//				app.gh.mouseUp(new MouseEvent(MouseEvent.MOUSE_UP, true, false, 0, 0, null));
				var prevTool:String = CursorTool.tool;
				CursorTool.tool = "copy";
				block.duplicateStack(app.mouseX - startX, app.mouseY - startY);
				CursorTool.tool = prevTool;
//				if (objToGrabOnUp != null) {
//					var prevTool:String = CursorTool.tool;
//					CursorTool.tool = "copy";
//					app.gh.grabOnMouseUp(objToGrabOnUp);
//					CursorTool.tool = prevTool;
//				}
				break;
			case "delete":
				block.deleteSelf();
				break;
			case "add comment":
				block.addComment();
				break;
			case "edit":
				editProcSpec();
				break;
			case "delete variable":
			case "delete list":
				deleteVarOrList();
				break;
			case "rename variable":
				renameVar(false);
				break;
			case "rename list":
				renameVar(true);
				break;
			case 'show senders':
				app.highlightSprites(app.runtime.allSendersOfBroadcast(block.args[0].argValue));
				break;
			case 'show receivers':
				app.highlightSprites(app.runtime.allReceiversOfBroadcast(block.args[0].argValue));
				break;
			case 'clear senders/receivers':
				app.highlightSprites([]);
				break;
			case "@@var":
			case "@@list":
				setBlockVarOrListName(evt.target.label);
				break;
			case "+":
			case "-":
			case "*":
			case "/":
			case "<":
			case "=":
			case ">":
				block.changeOperator(evt.target.name);
				break;
		}
	}

	private function changeOpMenu(evt:MouseEvent, opList:Array):void {
		/*
		function opMenu(selection:*):void {
			if (selection is Function) { selection(); return; }
			block.changeOperator(selection);
		}
		*/
		if (!block) return;
//		var m:Menu = new Menu(opMenu, 'changeOp');
		var m:NativeMenu = new NativeMenu();
		addGenericBlockItems(m);
		if (!isInPalette(block)){
			for each (var op:String in opList){
//				m.addItem(op);
				MenuUtil.AddItem(m, op);
			}
		}
		showMenu(m);
	}

	// ***** Procedure menu (for procedure definition hats and call blocks) *****

	private function procMenu(evt:MouseEvent):void {
//		var m:Menu = new Menu(null, 'proc');
		var m:NativeMenu = new NativeMenu();
		addGenericBlockItems(m);
		MenuUtil.AddItem(m, 'edit');
//		m.addItem('edit', editProcSpec);
		showMenu(m);
	}

	private function editProcSpec():void {
		if (block.op == Specs.CALL) {
			var def:Block = app.viewedObj().lookupProcedure(block.spec);
			if (!def) return;
			block = def;
		}
		var d:DialogBox = new DialogBox(editSpec2);
		d.addTitle('Edit Block');
		d.addWidget(new ProcedureSpecEditor(block.spec, block.parameterNames, block.warpProcFlag));
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage, true);
		ProcedureSpecEditor(d.widget).setInitialFocus();
	}

	private function editSpec2(dialog:DialogBox):void {
		var newSpec:String = ProcedureSpecEditor(dialog.widget).spec();
		if (newSpec.length == 0) return;
		if (block != null) {
			var oldSpec:String = block.spec;
			block.parameterNames = ProcedureSpecEditor(dialog.widget).inputNames();
			block.defaultArgValues = ProcedureSpecEditor(dialog.widget).defaultArgValues();
			block.warpProcFlag = ProcedureSpecEditor(dialog.widget).warpFlag();
			block.setSpec(newSpec);
			if (block.nextBlock) block.nextBlock.allBlocksDo(function(b:Block):void {
				if (b.op == Specs.GET_PARAM) b.parameterIndex = -1; // parameters may have changed; clear cached indices
			});
			for each (var caller:Block in app.runtime.allCallsOf(oldSpec, app.viewedObj())) {
				var oldArgs:Array = caller.args;
				caller.setSpec(newSpec, block.defaultArgValues);
				for (var i:int = 0; i < oldArgs.length; i++) {
					var arg:* = oldArgs[i];
					if (arg is BlockArg) arg = arg.argValue;
					caller.setArg(i, arg);
				}
				caller.fixArgLayout();
			}
		}
		app.runtime.updateCalls();
		app.updatePalette();
	}

	// ***** Variable and List menus *****

	private function listMenu(evt:MouseEvent):void {
//		var m:Menu = new Menu(varOrListSelection, 'list');
		var m:NativeMenu = new NativeMenu();
		m.addEventListener(Event.SELECT, __onSelect);
		if (block.op == Specs.GET_LIST) {
			if (isInPalette(block)){
				MenuUtil.AddItem(m, 'delete list');
				MenuUtil.AddItem(m, 'rename list');
//				m.addItem('delete list', deleteVarOrList); // list reporter in palette
			}
			addGenericBlockItems(m);
		} else {
			var t:NativeMenuItem;
			var listName:String;
			for each (listName in app.stageObj().listNames()){
//				m.addItem(listName);
				t = new NativeMenuItem(listName);
				t.name = "@@list";
				m.addItem(t);
			}
			if (!app.viewedObj().isStage) {
//				m.addLine();
				MenuUtil.AddLine(m);
				for each (listName in app.viewedObj().listNames()){
//					m.addItem(listName);
					t = new NativeMenuItem(listName);
					t.name = "@@list";
					m.addItem(t);
				}
			}
		}
		showMenu(m);
	}

	private function varMenu(evt:MouseEvent):void {
//		var m:Menu = new Menu(varOrListSelection, 'var');
		var m:NativeMenu = new NativeMenu();
		m.addEventListener(Event.SELECT, __onSelect);
		var isGetter:Boolean = (block.op == Specs.GET_VAR);
		if (isGetter && isInPalette(block)) { // var reporter in palette
//			m.addItem('rename variable', renameVar);
//			m.addItem('delete variable', deleteVarOrList);
			MenuUtil.AddItem(m, 'rename variable');
			MenuUtil.AddItem(m, 'delete variable');
			addGenericBlockItems(m);
		} else {
			if (isGetter) addGenericBlockItems(m);
			var myName:String = blockVarOrListName();
			var vName:String;
			var t:NativeMenuItem;
			for each (vName in app.stageObj().varNames()) {
				if(RobotHelper.isAutoVarName(vName)){
					continue;
				}
				if (!isGetter || (vName != myName)){
					t = new NativeMenuItem(vName);
					t.name = "@@var";
					m.addItem(t);
//					m.addItem(vName);
				}
			}
			if (!app.viewedObj().isStage) {
				MenuUtil.AddLine(m);
				for each (vName in app.viewedObj().varNames()) {
					if(RobotHelper.isAutoVarName(vName)){
						continue;
					}
					if (!isGetter || (vName != myName)){
						t = new NativeMenuItem(vName);
						t.name = "@@var";
						m.addItem(t);
					}
				}
			}
		}
		showMenu(m);
	}

	private function isInPalette(b:Block):Boolean {
		var o:DisplayObject = b;
		while (o != null) {
			if (o == app.palette) return true;
			o = o.parent;
		}
		return false;
	}
/*
	private function varOrListSelection(selection:*):void {
		if (selection is Function) { selection(); return; }
		setBlockVarOrListName(selection);
	}
*/
	private function renameVar(isList:Boolean):void {
		function doVarRename(dialog:DialogBox):void {
			var newName:String = dialog.fields['New name'].text.replace(/^\s+|\s+$/g, '');
			if(newName.length <= 0){
				return;
			}
			if(app.viewedObj().lookupVar(newName) || app.viewedObj().lookupList(newName)) {
				return;
			}
//			if (block.op != Specs.GET_VAR) return;
			if (block.op != Specs.GET_VAR && block.op != Specs.GET_LIST){
				return;
			}
			var oldName:String = blockVarOrListName();

			if (oldName.charAt(0) == '\u2601') { // Retain the cloud symbol
				newName = '\u2601 ' + newName;
			}

			if(isList){
				app.runtime.renameList(oldName, newName, block);
			}else{
				app.runtime.renameVariable(oldName, newName, block);
			}
			
			setBlockVarOrListName(newName);
			app.updatePalette();
		}
		var d:DialogBox = new DialogBox(doVarRename);
		d.addTitle(Translator.map('Rename') + ' ' + blockVarOrListName());
		d.addField('New name', 120);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function deleteVarOrList():void {
		function doDelete(selection:*):void {
			if (block.op == Specs.GET_VAR) {
				app.runtime.deleteVariable(blockVarOrListName());
			} else {
				app.runtime.deleteList(blockVarOrListName());
			}
			app.updatePalette();
			app.setSaveNeeded();
		}
		DialogBox.confirm(Translator.map('Delete') + ' ' + blockVarOrListName() + '?', app.stage, doDelete);
	}

	private function blockVarOrListName():String {
		return (blockArg != null) ? blockArg.argValue : block.spec;
	}

	private function setBlockVarOrListName(newName:String):void {
		if (newName.length == 0) return;
		if ((block.op == Specs.GET_VAR) || (block.op == Specs.SET_VAR) || (block.op == Specs.CHANGE_VAR)) {
			app.runtime.createVariable(newName);
		}
		if (blockArg != null) blockArg.setArgValue(newName);
		if (block != null) {
			if (block.op == Specs.GET_VAR) block.setSpec(newName);
		}
		MBlock.app.setSaveNeeded();
		app.updatePalette();
	}

	// ***** Color picker support *****

	public function dragBegin(evt:MouseEvent):void { }

	public function dragEnd(evt:MouseEvent):void {
		if (pickingColor) {
			pickingColor = false;
			Mouse.cursor = MouseCursor.AUTO;
		} else {
			pickingColor = true;
			app.gh.setDragClient(this, evt);
			Mouse.cursor = MouseCursor.BUTTON;
		}
	}

	public function dragMove(evt:MouseEvent):void {
		if (pickingColor) {
			blockArg.setArgValue(pixelColorAt(evt.stageX, evt.stageY));
			MBlock.app.setSaveNeeded();
		}
	}

	private var pickingColor:Boolean = false;
	private var onePixel:BitmapData = new BitmapData(1, 1);

	private function pixelColorAt(x:int, y:int):int {
		var m:Matrix = new Matrix();
		m.translate(-x, -y);
		onePixel.fillRect(onePixel.rect, 0);
		onePixel.draw(app, m);
		return onePixel.getPixel(0, 0) | 0xFF000000; // alpha is always 0xFF
	}

	// ***** Broadcast menu *****

	private function broadcastMenuSelection(selection:*):void {
		if (selection is Function) selection();
		else setBlockArg(selection);
	}
	private function broadcastMenu(evt:MouseEvent):void {
		var msgNames:Array = app.runtime.collectBroadcasts();
		if (msgNames.indexOf('message1') <= -1) msgNames.push('message1');
		msgNames.sort();

		var m:Menu = new Menu(broadcastMenuSelection, 'broadcast');
		for each (var msg:String in msgNames) m.addItem(msg);
		m.addLine();
		m.addItem('new message...', newBroadcast);
		showMenu(m);
	}

	private function changeBroadcast(dialog:DialogBox):void {
		var newName:String = dialog.fields['Message Name'].text;
		if (newName.length == 0) return;
		setBlockArg(newName);
	}
	private function newBroadcast():void {
		var d:DialogBox = new DialogBox(changeBroadcast);
		d.addTitle('New Message');
		d.addField('Message Name', 120);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function broadcastInfoMenu(evt:MouseEvent):void {
		/*
		function showBroadcasts(selection:*):void {
			if (selection is Function) { selection(); return; }
			var msg:String = block.args[0].argValue;
			var sprites:Array = [];
			if (selection == 'show senders') sprites = app.runtime.allSendersOfBroadcast(msg);
			if (selection == 'show receivers') sprites = app.runtime.allReceiversOfBroadcast(msg);
			if (selection == 'clear senders/receivers') sprites = [];
			app.highlightSprites(sprites);
		}
		var m:Menu = new Menu(showBroadcasts, 'broadcastInfo');
		*/
		var m:NativeMenu = new NativeMenu();
		addGenericBlockItems(m);
		if (!isInPalette(block)) {
			MenuUtil.AddItem(m, 'show senders');
			MenuUtil.AddItem(m, 'show receivers');
			MenuUtil.AddItem(m, 'clear senders/receivers');
		}
		showMenu(m);
	}
	
	static private var faceFrame:LightSetterFrame;
	
	private function drawFace(evt:MouseEvent):void
	{
		if(null == faceFrame){
			faceFrame = new LightSetterFrame();
		}
		faceFrame.init(blockArg.base.bmd);
		faceFrame.addEventListener(AWEvent.HIDDEN, __onFrameClose);
		faceFrame.addEventListener(Event.COMPLETE, __onFrameSelect);
		faceFrame.show();
	}
	
	private function __onFrameClose(evt:AWEvent):void
	{
		faceFrame.removeEventListener(AWEvent.HIDDEN, __onFrameClose);
		faceFrame.removeEventListener(Event.COMPLETE, __onFrameSelect);
	}
	
	private function __onFrameSelect(evt:Event):void
	{
		blockArg.argValue = faceFrame.getValue();
		blockArg.base.bmd = faceFrame.getBitmapData();
		blockArg.base.setColor(0);
		blockArg.base.redraw();
	}
}}
