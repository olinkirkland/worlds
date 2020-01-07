package layers {
    import flash.geom.Point;

    public class Wind {
        private var map:Map;

        public var windParticles:Vector.<WindParticle>;

        public function Wind(map:Map) {
            var spacing:int = 15;
            windParticles = new Vector.<WindParticle>();
            // Spawn starting wind particles on the top and bottom of the map pointing toward the center
            for (var i:int = spacing; i < map.width; i += spacing) {
                for (var j:int = spacing; j < map.height; j+= spacing) {
                    var w:WindParticle = new WindParticle(new Point(i, j), 90);
                    windParticles.push(w);
                }
            }
        }
    }
}
