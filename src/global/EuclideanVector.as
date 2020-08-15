package global
{
    import flash.geom.Point;

    public class EuclideanVector
    {
        private var _point:Point;
        public var angle:Number;
        public var magnitude:Number;

        public function EuclideanVector(angle:Number = 0, magnitude:Number = 0)
        {
            this.angle = angle;
            this.magnitude = magnitude;
            _point = getPoint();
        }

        public function get degrees():Number
        {
            return Util.toDegrees(angle);
        }

        public function add(v:EuclideanVector):void
        {
            var sum:Point = _point.add(v.getPoint());
            setPoint(sum);

            if (magnitude > 1)
                magnitude = 1;
            _point = getPoint();
        }

        public function getPoint():Point
        {
            var p:Point = new Point();
            p.x = Math.cos(angle) * magnitude;
            p.y = Math.sin(angle) * magnitude;
            return p;
        }

        public function setPoint(p:Point):void
        {
            _point = p;
            angle = Math.atan2(_point.y, _point.x);
            magnitude = _point.length;
        }

        public function toString():String
        {
            return "Euclidean Vector\n angle=" + angle + "\n magnitude=" + magnitude + "\n point=" + getPoint();
        }
    }
}
