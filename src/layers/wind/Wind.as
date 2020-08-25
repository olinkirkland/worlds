package layers.wind
{
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import global.Direction;

    import graph.Cell;

    import ui.Settings;

    public class Wind
    {
        private var map:Map;
        private var size:Number = 10;

        private var points:Array;
        private var grid:Array;
        public var gusts:Array;


        public function Wind(map:Map)
        {
            this.map = map;

            points = [];
            grid = [[]];
            gusts = [];

            var offset:Point = new Point(20, 20);
            var width:int = map.width - 40;
            var height:int = map.height - 40;

            var gust:Gust;
            for (var i:int = 0; i < width / size; i++)
            {
                grid [i] = [];
                for (var j:int = 0; j < height / size; j++)
                {
                    var p:Point = new Point(i * size + offset.x, j * size + offset.y);
                    gust = new Gust(p,
                            size);

                    points.push(p);
                    gusts.push(gust);
                    grid[i][j] = gust;
                }
            }

            // Set neighbors
            for (i = 0; i < grid.length; i++)
            {
                for (j = 0; j < grid[i].length; j++)
                {
                    gust = grid[i][j];

                    // North
                    if (i > 0)
                        gust.neighbors[Direction.WEST] = grid[i - 1][j];

                    // East
                    if (j < grid[i].length - 1)
                        gust.neighbors[Direction.SOUTH] = grid[i][j + 1];

                    // South
                    if (i < grid.length - 1)
                        gust.neighbors[Direction.EAST] = grid[i + 1][j];

                    // West
                    if (j > 0)
                        gust.neighbors[Direction.NORTH] = grid[i][j - 1];
                }
            }

            for each (gust in gusts)
            {
                var averageHeight:Number = 0;
                var quadPoints:Vector.<Point> = map.quadTree.query(new Rectangle(gust.point.x, gust.point.y, size, size));

                var ocean:Boolean = false;
                for each (p in quadPoints)
                {
                    var cell:Cell = map.getCellByPoint(p);
                    averageHeight += cell.elevation;
                    if (cell.ocean)
                        ocean = true;
                }

                if (ocean)
                {
                    gust.ocean = true;
                    gust.height = Map.seaLevel;
                }
                else
                {
                    averageHeight /= quadPoints.length;
                    gust.height = averageHeight >= 0 ? averageHeight : -1;
                }
            }

            // Smoothing for gusts that don't have any points under them
            for each (gust in gusts)
            {
                if (gust.height < 0)
                {
                    gust.height = 0;
                    i = 0;
                    for each (var neighbor:Gust in gust.neighbors)
                        if (neighbor && neighbor.height >= 0)
                        {
                            gust.height += neighbor.height;

                            if (neighbor.ocean)
                                gust.ocean = true;

                            i++;
                        }
                    gust.height /= i;
                }
            }

            startWinds();
            applyPrecipitationToCells();
        }

        private function startWinds():void
        {
            /**
             * Apply Initial Winds
             */

            var queue:Array = [];

            for (var i:int = 0; i < grid.length; i++)
            {
                for (var j:int = 0; j < grid[i].length; j++)
                {
                    var gust:Gust = grid[i][j];
                    // Default
                    gust.angle = Direction.SOUTH;
                    gust.strength = 0;
                    gust.moisture = 0;

                    // Prevailing East Wind
                    if (i == 0)
                    {
                        queue.push(gust);
                        gust.angle = Direction.EAST;
                        gust.strength = 1;
                    }

//                    // South Polar Wind
//                    if (j == grid[i].length - 1) {
//                        queue.push(gust);
//                        gust.angle = Direction.NORTH;
//                        gust.strength = 20;
//                    }
                }
            }

            propagate(queue);
        }

        public function propagate(queue:Array):void
        {
            /**
             * Propagate Wind
             */

            while (queue.length > 0)
            {
                var gust:Gust = queue.shift();
                var targets:Array = gust.send();

                for each (var target:Gust in targets)
                {
                    var containsTarget:Boolean = false;
                    for each (gust in queue)
                    {
                        if (gust == target)
                        {
                            containsTarget = true;
                            break;
                        }
                    }

                    if (!containsTarget)
                        queue.push(target);
                }
            }

            // Smooth
            for (var k:int = 0; k < Settings.advancedProperties.windSmoothing; k++)
                for each (gust in gusts)
                {
                    var averageStrength:Number = gust.strength;
                    var neighborCount:int = 0;
                    for each (var g:Gust in gust.neighbors)
                    {
                        if (g)
                        {
                            neighborCount++;
                            averageStrength += g.strength;
                        }
                    }

                    averageStrength /= neighborCount;
                    gust.strength = averageStrength;
                }
        }

        private function applyPrecipitationToCells():void
        {
            for each (var gust:Gust in gusts)
            {
                var quadPoints:Vector.<Point> = map.quadTree.query(new Rectangle(gust.point.x, gust.point.y, size * 2, size * 2));
                for each (var p:Point in quadPoints)
                {
                    var cell:Cell = map.getCellByPoint(p);
                    if (cell.ocean)
                        continue;

                    if (!cell.moisture)
                        cell.moisture = gust.precipitation;
                    else
                        cell.moisture = (cell.moisture + gust.precipitation) / 2;
                }
            }

            // Average and stretch the cell moisture
            for (var i:int = 0; i < 10; i++)
            {
                // Average
                var maxMoisture:Number = 0;
                for each (cell in map.cells)
                {
                    if (cell.ocean)
                        continue;

                    if (cell.moisture > maxMoisture)
                        maxMoisture = cell.moisture;

                    var average:Number = 0;
                    var neighborCount:int = 0;
                    for each (var neighbor:Cell in cell.neighbors)
                        if (neighbor.moisture && !neighbor.ocean)
                        {
                            average += neighbor.moisture;
                            neighborCount++;
                        }

                    cell.moisture = average /= neighborCount;
                }

                // Stretch
                for each (cell in map.cells)
                    if (cell.moisture)
                        cell.moisture *= (1 / maxMoisture);
            }

            for each (cell in map.cells)
                if (!cell.moisture)
                    cell.moisture = 0;
        }
    }
}
