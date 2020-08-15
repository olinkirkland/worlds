package layers.wind
{
    import flash.geom.Point;

    import global.EuclideanVector;
    import global.Util;

    import layers.wind.WindCell;

    public class WindCell
    {
        public var point:Point;
        public var size:Number;
        public var corners:Array;
        public var vector:EuclideanVector;
        public var neighbors:Object;
        public var elevation:Number;
        public var ocean:Boolean;

        public function WindCell(point:Point, size:Number)
        {
            this.point = point;
            this.size = size;

            vector = new EuclideanVector();
            neighbors = {};

            // Determine corners
            corners = [];
            for (var i:int = 30; i < 360; i += 60)
                corners.push(Util.pointFromAngleAndDistance(point, i, size));
        }

        public function propagate():Array
        {
            var angle1:Number;
            var angle2:Number;
            for (var i:int = 0; i < 360; i += 60)
            {
                if (i >= vector.degrees)
                {
                    angle2 = i;
                    angle1 = i - 60;
                    if (angle1 < 0)
                        angle1 += 360;
                    break;
                }
            }

            trace(vector.degrees + " is between " + angle1 + " and " + angle2);

            var angle1Distance:Number = Math.round(1024 * Math.abs(Util.differenceBetweenTwoDegrees(vector.angle, Util.toRadians(angle1)))) / 1024;
            var angle2Distance:Number = Math.round(1024 * Math.abs(Util.differenceBetweenTwoDegrees(vector.angle, Util.toRadians(angle2)))) / 1024;
            var angle1Ratio:Number = 1 - angle1Distance / 60;
            var angle2Ratio:Number = 1 - angle2Distance / 60;

            trace(angle1 + " is " + angle1Distance + " away");
            trace(angle2 + " is " + angle2Distance + " away");
            trace(angle1 + "=" + int(angle1Ratio * 100) + "%, " + angle2 + "=" + int(angle2Ratio * 100) + "%");

            var arr:Array = [];
            if (neighbors[angle1] && angle1Ratio > 0)
            {
                WindCell(neighbors[angle1]).vector.add(new EuclideanVector(Util.toRadians(angle1), angle1Ratio * vector.magnitude));
                arr.push(neighbors[angle1]);
            }
            if (neighbors[angle2] && angle2Ratio > 0)
            {
                WindCell(neighbors[angle2]).vector.add(new EuclideanVector(Util.toRadians(angle2), angle2Ratio * vector.magnitude));
                arr.push(neighbors[angle2]);
            }

            return arr;
        }
    }
}