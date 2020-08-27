package ui
{
    import flash.net.SharedObject;

    import mx.utils.ObjectUtil;

    public class Settings
    {
        private static var shared:SharedObject;

        private static var _initialLayers:Array;
        public static var defaultInitialLayers:Array = ["relief", "continents", "ocean", "precipitation", "rivers"];

        private static var _properties:Object;
        public static var defaultProperties:Object = {
            spacing:                          6,
            precision:                        5,
            smoothing:                        5,
            seaLevel:                         .35,
            tectonicJitter:                   0.2,
            plateCount:                       15,
            cloudMoistureCapacity:            25,
            moistureGainedOverOcean:          3,
            windStrengthGainedOverOcean:      .1,
            windStrengthLostOverLand:         .1,
            windSmoothing:                    3,
            windStrengthHeightChangeModifier: 3,
            riverMoistureThreshold:           .2,
            riverMinimumStemLength:           5,
            riverMinimumTributaryLength:      3,
            reliefBlur:                       0,
            poleTemperatureModifier:          1.2,
            elevationTemperatureModifier:     1,
            language:                         "en"
        };

        public static var biomeColors:Object = {
            tundra:              0xBFA0EA,
            borealForest:        0x005400,
            grassland:           0xFFFF00,
            shrubland:           0xF9B233,
            seasonalForest:      0x45B145,
            temperateRainforest: 0x45B145,
            desert:              0xF94A00,
            tropicalRainforest:  0x00FF00
        };

        public static function get initialLayers():Array
        {
            // Load from shared
            if (!_initialLayers)
            {
                shared = SharedObject.getLocal("settings");
                _initialLayers = shared.data.initialLayers;
                if (!_initialLayers)
                    _initialLayers = defaultInitialLayers.concat();
            }

            return _initialLayers;
        }

        public static function set initialLayers(value:Array):void
        {
            _initialLayers = value;

            shared.data.initialLayers = value;
        }

        public static function get properties():Object
        {
            // Load from shared
            if (!_properties)
            {
                shared = SharedObject.getLocal("settings");
                _properties = shared.data.properties;
                if (!_properties)
                    _properties = ObjectUtil.clone(defaultProperties);
            }

            // Ensure that any values not specified in the loaded settings are applied
            for (var key:String in defaultProperties)
                if (!_properties.hasOwnProperty(key))
                    _properties[key] = defaultProperties[key];

            return _properties;
        }

        public static function set properties(value:Object):void
        {
            _properties = value;

            shared.data.properties = value;
        }
    }
}
