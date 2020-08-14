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

        public function merge(force:Force):Boolean
        {
            trace(force.angle, strength);

            // Merge another force into this one
            var origin:Point = new Point(0, 0);
            var position:Point = Util.pointFromAngleAndDistance(origin, angle, strength);
            var sum:Point = Util.pointFromAngleAndDistance(position, force.angle, force.strength);

            angle = Math.round(Util.angleBetweenTwoPoints(origin, sum));
            strength = Util.distanceBetweenTwoPoints(origin, sum);

            if (angle < 0)
                angle += 360;

            return strength > .05;
        }
    }
}
