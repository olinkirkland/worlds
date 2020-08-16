package ui
{
    import flash.net.SharedObject;

    import mx.utils.ObjectUtil;

    public class AdvancedPropertiesUtil
    {
        public static var defaultValues:Object = {
            spacing:                          8,
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
            windStrengthHeightChangeModifier: 3
        };

        private static var _currentValues:Object;

        public static function get currentValues():Object
        {
            // Load from shared
            if (!_currentValues)
            {
                var shared:SharedObject = SharedObject.getLocal("Shared");
                _currentValues = shared.data.advancedProperties;

                // Ensure that any values not specified in the loaded settings are applied
                for (var key:String in defaultValues)
                    if (!_currentValues.hasOwnProperty(key))
                        _currentValues[key] = defaultValues[key];
            }

            if (!_currentValues)
                _currentValues = ObjectUtil.clone(defaultValues);

            return _currentValues;
        }

        public static function set currentValues(value:Object):void
        {
            _currentValues = value;

            var shared:SharedObject = SharedObject.getLocal("Shared");
            shared.data.advancedProperties = value;
        }
    }
}
