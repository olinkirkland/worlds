package layers.wind
{
    import flash.geom.Point;

    import global.Direction;

    import global.Util;


    public class WindCell
    {
        public var point:Point;
        public var size:Number;
        public var corners:Array;
        public var force:Force;
        public var neighbors:Array;

        private var appliedForces:Array;

        public function WindCell(point:Point, size:Number)
        {
            this.point = point;
            this.size = size;

            // Reset force (angle + strength)
            force = new Force();
            appliedForces = [];

            // Determine corners
            corners = [];
            for (var i:int = 30; i < 360; i += 60)
                corners.push(Util.pointFromDegreesAndDistance(point, i, size));
        }

        public function reset():void
        {
            force = new Force();
        }
    }
}
