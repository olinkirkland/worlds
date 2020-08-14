package layers.wind
{
    import flash.geom.Point;

    public class Wind
    {
        public var windCells:Array;

        private var map:Map;
        private var size:Number = 10;

        public var points:Array;
        private var rows:Array = [];

        public function Wind(map:Map)
        {
            this.map = map;

            points = [];
            windCells = [];

            makePoints();
            for (var i:int = 0; i < rows.length; i++)
            {
                var offset:Boolean = i % 2 != 0;
                var row:Array = rows[i];
                for (var j:int = 0; j < row.length; j++)
                {
                    var c:WindCell = new WindCell(row[j], size);
                    windCells.push(c);

                    // Set neighbors

                    // Middle
                    if (i > 0) c.neighbors.push(row[i - 1]);
                    if (i < row.length - 1) c.neighbors.push(row[i + 1]);

                    if (offset)
                    {
                        // Upper


                        // Lower


                    } else
                    {
                        // Upper


                        // Lower


                    }
                }
            }


//            for each (gust in windCells)
//            {
//                var averageHeight:Number = 0;
//                var quadPoints:Vector.<Point> = map.quadTree.query(new Rectangle(gust.point.x, gust.point.y, size, size));
//
//                var ocean:Boolean = false;
//                for each (p in quadPoints)
//                {
//                    var cell:Cell = map.getCellByPoint(p);
//                    averageHeight += cell.elevation;
//                    if (cell.ocean)
//                        ocean = true;
//                }
//
//                if (ocean)
//                {
//                    gust.ocean = true;
//                    gust.height = Map.seaLevel;
//                } else
//                {
//                    averageHeight /= quadPoints.length;
//                    gust.height = averageHeight >= 0 ? averageHeight : -1;
//                }
//            }

            // Smoothing for windCells that don't have any points under them
//            for each (gust in windCells)
//            {
//                if (gust.height < 0)
//                {
//                    gust.height = 0;
//                    i = 0;
//                    for each (var neighbor:WindCell in gust.neighbors)
//                        if (neighbor && neighbor.height >= 0)
//                        {
//                            gust.height += neighbor.height;
//
//                            if (neighbor.ocean)
//                                gust.ocean = true;
//
//                            i++;
//                        }
//                    gust.height /= i;
//                }
//            }

            //startWinds();
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
                rows.push([]);
                var row:Array = rows[rows.length - 1];
                var offset:Number = rows.length % 2 == 0 ? 0 : w / 2;

                for (var j:int = 0; j < map.width; j += w)
                {
                    var p:Point = new Point(j + offset, i);
                    points.push(p);
                    row.push(p);
                }
            }
        }

        private function startWinds():void
        {
            /**
             * Apply Initial Winds
             */

            var queue:Array = [];

            propagateWindCells(queue);
        }

        public function propagateWindCells(queue:Array):void
        {
            /**
             * Propagate Wind
             */

//            while (queue.length > 0)
//            {
//                var w:WindCell = queue.shift();
//                var targets:Array = w.propagate();
//
//                for each (var target:WindCell in targets)
//                {
//                    var containsTarget:Boolean = false;
//                    for each (w in queue)
//                    {
//                        if (w == target)
//                        {
//                            containsTarget = true;
//                            break;
//                        }
//                    }
//
//                    if (!containsTarget)
//                        queue.push(target);
//                }
//            }
        }
    }
}
