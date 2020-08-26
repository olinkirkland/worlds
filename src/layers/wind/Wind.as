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
        private var size:Number = 20;

        private var points:Array;
        private var grid:Array;
        public var clouds:Array;


        public function Wind(map:Map)
        {
            this.map = map;

            points = [];
            grid = [[]];
            clouds = [];

            var offset:Point = new Point(20, 20);
            var width:int = map.width - 40;
            var height:int = map.height - 40;

            var cloud:Cloud;
            for (var i:int = 0; i < width / size; i++)
            {
                grid [i] = [];
                for (var j:int = 0; j < height / size; j++)
                {
                    var p:Point = new Point(i * size + offset.x, j * size + offset.y);
                    cloud = new Cloud(p,
                            size);

                    points.push(p);
                    clouds.push(cloud);
                    grid[i][j] = cloud;
                }
            }

            // Set neighbors
            for (i = 0; i < grid.length; i++)
            {
                for (j = 0; j < grid[i].length; j++)
                {
                    cloud = grid[i][j];

                    // North
                    if (i > 0)
                        cloud.neighbors[Direction.WEST] = grid[i - 1][j];

                    // East
                    if (j < grid[i].length - 1)
                        cloud.neighbors[Direction.SOUTH] = grid[i][j + 1];

                    // South
                    if (i < grid.length - 1)
                        cloud.neighbors[Direction.EAST] = grid[i + 1][j];

                    // West
                    if (j > 0)
                        cloud.neighbors[Direction.NORTH] = grid[i][j - 1];
                }
            }

            for each (cloud in clouds)
            {
                var averageHeight:Number = 0;
                var quadPoints:Vector.<Point> = map.quadTree.query(new Rectangle(cloud.point.x, cloud.point.y, size, size));

                cloud.ocean = true;
                for each (p in quadPoints)
                {
                    var cell:Cell = map.getCellByPoint(p);
                    averageHeight += cell.elevation;
                    if (!cell.ocean)
                        cloud.ocean = false;
                }

                averageHeight /= quadPoints.length;
                cloud.height = averageHeight >= 0 ? averageHeight : -1;

                if (cloud.ocean)
                    cloud.height = Map.seaLevel;
            }

            // Smoothing for clouds that don't have any points under them
            for each (cloud in clouds)
            {
                if (cloud.height < 0)
                {
                    cloud.height = 0;
                    i = 0;
                    for each (var neighbor:Cloud in cloud.neighbors)
                        if (neighbor && neighbor.height >= 0)
                        {
                            cloud.height += neighbor.height;

                            if (neighbor.ocean)
                                cloud.ocean = true;

                            i++;
                        }
                    cloud.height /= i;
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
                    var cloud:Cloud = grid[i][j];
                    // Default
                    cloud.angle = Direction.SOUTH;
                    cloud.strength = 0;
                    cloud.moisture = 0;

                    // Prevailing East Wind
                    if (i == 0)
                    {
                        queue.push(cloud);
                        cloud.angle = Direction.EAST;
                        cloud.strength = 1;
                        cloud.moisture = Settings.advancedProperties.cloudMoistureCapacity;
                    }

//                    // South Polar Wind
//                    if (j == grid[i].length - 1) {
//                        queue.push(cloud);
//                        cloud.angle = Direction.NORTH;
//                        cloud.strength = 20;
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

            var cloud:Cloud = null;
            while (queue.length > 0)
            {
                cloud = queue.shift();
                var targets:Array = cloud.send();

                for each (var target:Cloud in targets)
                {
                    var containsTarget:Boolean = false;
                    for each (cloud in queue)
                    {
                        if (cloud == target)
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
                for each (cloud in clouds)
                {
                    var averageStrength:Number = cloud.strength;
                    var neighborCount:int = 0;

                    for each (var c:Cloud in cloud.neighbors)
                    {
                        if (c)
                        {
                            neighborCount++;
                            averageStrength += c.strength;
                        }
                    }

                    averageStrength /= neighborCount;
                    cloud.strength = averageStrength;
                }
        }

        private function applyPrecipitationToCells():void
        {
            for each (var cloud:Cloud in clouds)
            {
                var quadPoints:Vector.<Point> = map.quadTree.query(new Rectangle(cloud.point.x, cloud.point.y, size, size));
                for each (var p:Point in quadPoints)
                {
                    var cell:Cell = map.getCellByPoint(p);
                    if (cell.ocean)
                        continue;

                    if (!cell.moisture)
                        cell.moisture = cloud.precipitation;
                    else
                        cell.moisture = (cell.moisture + cloud.precipitation) / 2;
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
                        if (neighbor.moisture)
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
