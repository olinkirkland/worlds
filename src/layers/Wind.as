package layers {
    import flash.geom.Point;

    import global.Direction;

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
                    var w:AirParticle = new AirParticle(new Point(j, i), Direction.SOUTH, 0);
                    column.push(w);
                    airParticles.push(w);
                }
            }

            for (i = 0; i < rows.length; i++) {
                for (j = 0; j < rows[i].length; j++) {
                    w = rows[i][j];

                    if (i > 0)
                        w.north = rows[i - 1][j];
                    if (j > 0)
                        w.east = rows[i][j--];
                    if (i < rows.length)
                        w.south = rows[i + 1][j];
                    if (j < rows[i].length)
                        w.west = rows[i][j - 1];
                }
            }

            // Hardcoded wind (pressure at poles)
            for each (w in rows[0])
                w.strength = 7;
            for each (w in rows[rows.length - 1]) {
                w.strength = 7;
                w.direction = Direction.NORTH;
            }
        }
    }
}
