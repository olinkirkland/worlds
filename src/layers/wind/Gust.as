package layers.wind
{
    import flash.geom.Point;

    import ui.Settings;

    public class Gust
    {
        public var point:Point;
        public var size:Number;
        public var height:Number;

        public var corners:Array;

        public var angle:Number;
        public var strength:Number;

        public var neighbors:Object;
        public var ocean:Boolean;
        public var moisture:Number;
        public var precipitation:Number;


        private var moistureCapacity:Number;
        private var moistureGainedOverOcean:Number;
        private var strengthGainedOverOcean:Number;
        private var strengthLostOverLand:Number;

        public function Gust(point:Point,
                             size:Number)
        {
            moistureCapacity = Settings.advancedProperties.cloudMoistureCapacity;
            moistureGainedOverOcean = Settings.advancedProperties.moistureGainedOverOcean;
            strengthGainedOverOcean = Settings.advancedProperties.windStrengthGainedOverOcean;
            strengthLostOverLand = Settings.advancedProperties.windStrengthLostOverLand;

            this.point = point;
            this.size = size;

            corners = [new Point(point.x, point.y),
                new Point(point.x + size, point.y),
                new Point(point.x + size, point.y + size),
                new Point(point.x, point.y + size)];

            point.x += size / 2;
            point.y += size / 2;

            neighbors = {0: null, 90: null, 180: null, 270: null};
        }

        public function send():Array
        {
            var neighbor:Gust = neighbors[angle];
            if (!neighbor)
                return [];

            // Calculate the height difference to the neighbor
            var heightDifference:Number = height - neighbor.height;
            heightDifference = int(heightDifference * 1000) / 1000;
            heightDifference *= Settings.advancedProperties.windStrengthHeightChangeModifier;

            // Decrease speed going uphill (and increase going downhill)
            var outgoingStrength:Number = strength * (1 - heightDifference);

            if (ocean)
            {
                // Pick up moisture from the ocean
                if (moisture < moistureCapacity)
                    moisture += moistureGainedOverOcean;

                precipitation = 0;
                // Pick up speed from the ocean
                outgoingStrength += strengthGainedOverOcean;
            }
            else
            {
                // Calculate precipitation and subtract it from the moisture
                precipitation = moisture / 5;
                moisture -= Math.min(moisture, precipitation);

                // Decrease speed over land
                outgoingStrength -= strengthLostOverLand;
            }

            outgoingStrength = Math.max(0, Math.min(outgoingStrength, 1));

            neighbor.angle = angle;
            neighbor.strength = outgoingStrength;
            neighbor.moisture = moisture;

            return [neighbor];
        }
    }
}
