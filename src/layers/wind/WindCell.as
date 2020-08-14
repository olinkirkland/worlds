package layers.wind
{
    import flash.geom.Point;
    import flash.geom.Vector3D;

    import global.Util;

    public class WindCell
    {
        public var point:Point;
        public var size:Number;
        public var corners:Array;
        public var force:Vector3D;
        public var neighbors:Array;
        public var elevation:Number;
        public var ocean:Boolean;

        private var appliedForces:Array;

        public function WindCell(point:Point, size:Number)
        {
            this.point = point;
            this.size = size;

            // Reset force (angle + strength)
            force = new Force();
            appliedForces = [];
            neighbors = [];

            // Determine corners
            corners = [];
            for (var i:int = 30; i < 360; i += 60)
                corners.push(Util.pointFromAngleAndDistance(point, i, size));
        }

        public function getAffectedNeighbors():Array
        {
            var targets:Array = [];
            for each (var neighbor:WindCell in neighbors)
            {
                var angleToNeighbor:Number = Util.roundToNearest(Util.angleBetweenTwoPoints(point, neighbor.point), 30);
                if (Math.abs(Util.differenceBetweenTwoDegrees(force.angle, angleToNeighbor)) < 90)
                    targets.push({windCell: neighbor, angle: angleToNeighbor});
            }

            var affectedNeighbors:Array = [];
            for each (var target:Object in targets)
                affectedNeighbors.push(target.windCell);

            return affectedNeighbors;
        }

        public function propagate():Array
        {
            // Split up my force and merge it into my neighbors
            // then return the affected neighbors
            var targets:Array = [];
            for each (var neighbor:WindCell in neighbors)
            {
                var angleToNeighbor:Number = Util.roundToNearest(Util.angleBetweenTwoPoints(point, neighbor.point), 30);
                if (Math.abs(Util.differenceBetweenTwoDegrees(force.angle, angleToNeighbor)) < 60)
                    targets.push({windCell: neighbor, angle: angleToNeighbor});
            }

            var affectedNeighbors:Array = [];
            for each (var target:Object in targets)
            {
                var strengthPercent:Number = Util.differenceBetweenTwoDegrees(force.angle, target.angle) / 60;
                var w:WindCell = target.windCell;
                if (w.force.merge(new Force(target.angle, strengthPercent * force.strength)))
                    affectedNeighbors.push(w);
            }

            return [];
        }

        public function reset():void
        {
            force = new Force();
        }
    }
}
