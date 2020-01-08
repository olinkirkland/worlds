package layers {
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import global.Direction;
    import global.Util;

    import graph.Cell;
    import graph.QuadTree;

    import layers.AirParticle;

    public class Wind {
        private var map:Map;

        public var airParticles:Vector.<AirParticle>;

        public function Wind(map:Map) {
            var minimumSpacing:Number = 20;
            var horizontalSpacing:int = map.width / (map.width / minimumSpacing);
            var verticalSpacing:int = map.height / (map.height / minimumSpacing);

            // Generate a particle grid
            airParticles = new Vector.<AirParticle>();
            var rows:Array = [];
            for (var i:int = verticalSpacing; i < map.height; i += verticalSpacing) {
                var column:Array = [];
                rows.push(column);
                for (var j:int = horizontalSpacing; j < map.width; j += horizontalSpacing) {
                    var w:AirParticle = new AirParticle(new Point(j, i), -1, 0);
                    column.push(w);
                    airParticles.push(w);
                }
            }

            for (i = 0; i < rows.length; i++) {
                for (j = 0; j < rows[i].length; j++) {
                    w = rows[i][j];

                    if (i > 0)
                        w.north = rows[i - 1][j];
                    if (i < rows.length - 1)
                        w.south = rows[i + 1][j];
                }
            }

            // Hardcoded wind (pressure at poles)
            for each (w in rows[0]) {
                w.direction = Direction.SOUTH;
                w.speed = 1;
            }
            for each (w in rows[rows.length - 1]) {
                w.direction = Direction.NORTH;
                w.speed = 1;
            }

            // Run
            var queue:Array = rows[0].concat(rows[rows.length - 1]);
            while (queue.length > 0) {
                w = queue.shift();

                var cell:Cell = map.getCellByPoint(Util.closestPoint(w.point, map.quadTree.query(new Rectangle(w.point.x - 20, w.point.y - 20, 40, 40))));
                w.height = cell ? cell.height : 0;
                if (w.from && cell && !cell.ocean) {
                    var diff:Number = w.height - w.from.height;
                    w.speed -= diff * 5;
                    if (w.speed < 0) w.speed = 0;
                }

                var neighbor:AirParticle = w.step();
                if (neighbor)
                    queue.push(neighbor);
            }
        }

        public function getClosestAirParticle(p:Point):AirParticle {
            var closest:AirParticle = airParticles[0];
            for each (var current:AirParticle in airParticles) {
                if (Point.distance(p, current.point) < Point.distance(p, closest.point))
                    closest = current;
            }

            return closest;
        }
    }
}
