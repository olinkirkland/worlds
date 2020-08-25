package ui
{
    import flash.net.SharedObject;

    import mx.utils.ObjectUtil;

    public class Settings
    {
        private static var shared:SharedObject;

        private static var _initialLayers:Array;
        public static var defaultInitialLayers:Array = ["relief", "continents", "ocean", "precipitation", "rivers"];

        private static var _advancedProperties:Object;
        public static var defaultAdvancedProperties:Object = {
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
            riverMinimumTributaryLength:      3
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

        public static function get advancedProperties():Object
        {
            // Load from shared
            if (!_advancedProperties)
            {
                shared = SharedObject.getLocal("settings");
                _advancedProperties = shared.data.advancedProperties;
                if (!_advancedProperties)
                    _advancedProperties = ObjectUtil.clone(defaultAdvancedProperties);
            }

            // Ensure that any values not specified in the loaded settings are applied
            for (var key:String in defaultAdvancedProperties)
                if (!_advancedProperties.hasOwnProperty(key))
                    _advancedProperties[key] = defaultAdvancedProperties[key];

            return _advancedProperties;
        }

        public static function set advancedProperties(value:Object):void
        {
            _advancedProperties = value;

            shared.data.advancedProperties = value;
        }
    }
}
