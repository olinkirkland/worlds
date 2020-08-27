package lang
{
    import ui.Settings;


    public class Lang
    {
        [Embed(source="/assets/languages/english.json", mimeType='application/octet-stream')]
        private static const EN:Class;
        private static const en:String = new EN();

        private static var language:Object;

        public function Lang()
        {
        }

        public static function loadLanguage():void
        {
            try
            {
                language = JSON.parse(Lang[Settings.properties.language]);
            } catch (error:Error)
            {
                // Failed to find that file, load en instead
                language = JSON.parse(Lang[en]);
            }
        }

        public static function getText(id:String):String
        {
            if (!language)
                loadLanguage();

            // Returns the value of id if it exists and returns the id if a value cannot be found
            return (language.hasOwnProperty(id)) ? language[id] : "[" + id + "]";
        }
    }
}
