package layers.wind
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import global.Direction;

    import graph.Cell;

    public class Wind
    {
        public var windCells:Array = [];
        public var windCellsByPoint:Object = {};

        private var map:Map;
        private var size:Number = 30;

        public var points:Array = [];
        private var pointsRows:Array = [];
        private var windCellRows:Array = [];

        public function Wind(map:Map)
        {
            this.map = map;

            makePoints();
            for (var i:int = 0; i < pointsRows.length; i++)
            {
                var pointsRow:Array = pointsRows[i];
                var windCellRow:Array = [];
                windCellRows.push(windCellRow);

                for (var j:int = 0; j < pointsRow.length; j++)
                {
                    var c:WindCell = new WindCell(pointsRow[j], size);
                    windCells.push(c);
                    windCellRow[j] = windCellsByPoint[pointsRow[j]] = c;
                }
            }

            // Set neighbors
            for (i = 0; i < windCellRows.length; i++)
            {
                var offset:int = (i % 2 == 0) ? 0 : -1;
                windCellRow = windCellRows[i];

                for (j = 0; j < windCellRow.length; j++)
                {
                    c = windCellRow[j];

                    // Middle
                    var row:Array = windCellRow;
                    if (j > 0)
                        c.neighbors.push(row[j - 1]);
                    if (j < row.length - 2)
                        c.neighbors.push(row[j + 1]);

                    var k:int = j + offset;
                    // Above
                    if (i > 0)
                    {
                        row = windCellRows[i - 1];
                        if (k >= 0)
                            c.neighbors.push(row[k]);
                        if (k < row.length - 1)
                            c.neighbors.push(row[k + 1]);
                    }

                    // Below
                    if (i < windCellRows.length - 1)
                    {
                        row = windCellRows[i + 1];
                        if (k >= 0)
                            c.neighbors.push(row[k]);
                        if (k < row.length - 1)
                            c.neighbors.push(row[k + 1]);
                    }
                }
            }


            for each (c in windCellsByPoint)
            {
                var averageElevation:Number = 0;
                var quadPoints:Vector.<Point> = map.quadTree.query(new Rectangle(c.point.x, c.point.y, size * 2, size * 2));

                var ocean:Boolean = false;
                for each (var p:Point in quadPoints)
                {
                    var cell:Cell = map.getCellByPoint(p);
                    averageElevation += cell.elevation;
                    if (cell.ocean)
                        ocean = true;
                }

                averageElevation /= quadPoints.length;
                c.elevation = averageElevation >= 0 ? averageElevation : -1;

                if (ocean && c.elevation <= Map.seaLevel)
                {
                    c.ocean = true;
                    c.elevation = Map.seaLevel;
                }
            }

            // Smoothing for windCellsByPoint that don't have any points under them
            for each (c in windCellsByPoint)
            {
                if (c.elevation < 0)
                {
                    c.elevation = 0;
                    i = 0;

                    ocean = false;

                    for each (var neighbor:WindCell in c.neighbors)
                    {
                        if (neighbor.elevation >= 0)
                        {
                            c.elevation += neighbor.elevation;
                            i++;
                        }

                        if (neighbor.ocean)
                        {
                            c.ocean = true;
                            c.elevation = Map.seaLevel;
                            break;
                        }
                    }

                    if (!c.ocean)
                        c.elevation /= i;
                }
            }

            applyInitialWind();
        }

        private function makePoints():void
        {
            var w:Number = Math.sqrt(3) * size;
            var h:Number = 3 / 2 * size;

            var extraRow:Boolean = true;
            for (var i:int = 0; i < map.height || extraRow; i += h)
            {
                if (i >= map.height)
                    extraRow = false;

                // Add a new row
                pointsRows.push([]);
                var row:Array = pointsRows[pointsRows.length - 1];
                var offset:Number = pointsRows.length % 2 == 0 ? 0 : w / 2;

                for (var j:int = 0; j < map.width; j += w)
                {
                    var p:Point = new Point(j + offset, i);
                    points.push(p);
                    row.push(p);
                }
            }
        }

        private function applyInitialWind():void
        {
            /**
             * Apply Initial Winds
             */

            var queue:Array = [];

            var row:Array = windCellRows[0];
//            var c:WindCell = row[int(row.length / 2)];
//            queue.push(c);

//            queue.push(row[int(row.length / 2) - 1]);
//            queue.push(row[int(row.length / 2) + 1]);

//            for each (c in queue)
//            {
//                c.force.angle = Direction.SOUTH;
//                c.force.strength = 1;
//            }

            // Polar north wind
            for each (var c:WindCell in windCellRows[0])
            {
                queue.push(c);
                c.force.angle = Direction.SOUTH;
                c.force.strength = 1;
            }

            //propagateWindCells(queue);
        }

        public function propagateWindCells(queue:Array):void
        {
            /**
             * Propagate Wind
             */

            while (queue.length > 0)
            {
                var c:WindCell = queue.shift();
                var targets:Array = c.propagate();

                for each (var t:WindCell in targets)
                    if (queue.indexOf(t) < 0)
                        queue.push(t);
            }
        }

        public function closestCellToPoint(p:Point):WindCell
        {
            if (!p)
                return null;

            var closest:WindCell = windCells[0];
            for each (var h:WindCell in windCellsByPoint)
                if (Point.distance(h.point, p) < Point.distance(closest.point, p))
                    closest = h;

            return closest;
        }
    }
}
