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
            trace("BEFORE: " + degrees + ", " + magnitude);
            trace("ADD: " + v.degrees + ", " + v.magnitude);
            var sum:Point = _point.add(v.getPoint());
            setPoint(sum);

            if (magnitude > 1)
                magnitude = 1;
            _point = getPoint();

            trace("NOW: " + degrees + ", " + magnitude);
        }

        public function getPoint():Point
        {
            var p:Point = new Point();
            p.x = Math.cos(angle) * magnitude;
            p.y = Math.sin(angle) * magnitude;

            p.x = Math.round(1024 * p.x) / 1024;
            p.y = Math.round(1024 * p.y) / 1024;
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
