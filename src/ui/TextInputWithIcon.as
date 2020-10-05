package ui
{

    import flash.events.Event;

    import mx.core.mx_internal;

    import spark.components.RichEditableText;
    import spark.components.TextInput;
    import spark.primitives.BitmapImage;

    use namespace mx_internal;

    [Event(name="enter", type="mx.events.FlexEvent")]

    [Exclude(name="verticalAlign", kind="style")]
    [Exclude(name="lineBreak", kind="style")]

    [DefaultProperty("text")]
    [DefaultTriggerEvent("change")]

    [IconFile("TextInput.png")]

    [Style(name="icon", type="Object", inherit="no")]

    public class TextInputWithIcon extends TextInput
    {
        [SkinPart(required="false")]
        public var iconDisplay:BitmapImage;

        public function TextInputWithIcon()
        {
            super();
        }

        private static const focusExclusions:Array = ["textDisplay"];

        override public function get suggestedFocusSkinExclusions():Array
        {
            return focusExclusions;
        }

        [Bindable("change")]
        [Bindable("textChanged")]

        // Compiler will strip leading and trailing whitespace from text string.
        [CollapseWhiteSpace]

        override public function set text(value:String):void
        {
            super.text = value;

            // Trigger bindings to textChanged.
            dispatchEvent(new Event("textChanged"));
        }

        [Inspectable(category="General", minValue="0.0")]

        override protected function partAdded(partName:String, instance:Object):void
        {
            super.partAdded(partName, instance);

            if (instance == textDisplay)
            {
                textDisplay.multiline = false;
                textDisplay.lineBreak = "explicit";
                if (textDisplay is RichEditableText)
                    RichEditableText(textDisplay).heightInLines = 1;
            }
            else if (instance == iconDisplay)
            {
                iconDisplay.source = getStyle("icon");
            }
        }

        override public function styleChanged(styleProp:String):void
        {
            if (!styleProp ||
                    styleProp == "styleName" ||
                    styleProp == "icon")
            {
                if (iconDisplay)
                    iconDisplay.source = getStyle("icon");
            }

            super.styleChanged(styleProp);
        }

    }

}
