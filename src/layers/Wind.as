package layers {
    import flash.geom.Point;

    public class Wind {
        private var map:Map;

        public var windParticles:Vector.<WindParticle>;

        public function Wind(map:Map) {
            var minimumSpacing:Number = 15;
            var horizontalSpacing:int = map.width / (map.width / minimumSpacing);
            var verticalSpacing:int = map.height / (map.height / minimumSpacing);

            windParticles = new Vector.<WindParticle>();
            // Spawn starting wind particles on the top and bottom of the map pointing toward the center
            for (var i:int = horizontalSpacing; i < map.width; i += horizontalSpacing) {
                for (var j:int = verticalSpacing; j < map.height; j += verticalSpacing) {
                    var w:WindParticle = new WindParticle(new Point(i, j), 90);
                    windParticles.push(w);
                }
            }
        }
    }
}
