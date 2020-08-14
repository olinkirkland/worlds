package layers.wind
{
    import flash.geom.Point;

    import global.Util;

    public class Force
    {
        public var angle:Number;
        public var strength:Number;

        public function Force(angle:Number = 0, strength:Number = 0)
        {
            this.angle = angle;
            this.strength = strength;
        }

        public function merge(force:Force):void
        {
            // Merge another force into this one
            var origin:Point = new Point(0, 0);
            var destination:Point = Util.pointFromDegreesAndDistance(origin, angle, strength);

            var combinedDestination:Point = Util.pointFromDegreesAndDistance(destination, force.angle, force.strength);
            angle = Math.floor(Util.angleBetweenTwoPoints(origin, combinedDestination));
            strength = Util.distanceBetweenTwoPoints(origin, combinedDestination);
            
            if (angle < 0)
                angle += 360;
        }
    }
}
