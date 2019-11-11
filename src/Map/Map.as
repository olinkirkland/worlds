package Map {
    import Map.QuadTree.QuadTree;

    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class Map {

        public var points:Vector.<Point>;

        public var quadTree:QuadTree;
        private var bounds:Rectangle;

        public function Map(width:int, height:int, pointCount:int) {
            points = makePoints(width, height, pointCount);
            bounds = new Rectangle(0, 0, width, height);

            makeQuadTreeForPoints();
        }

        private function makeQuadTreeForPoints():void {
            quadTree = new QuadTree(bounds);
            for each (var point:Point in points)
                quadTree.insert(point);
        }

        public static function makePoints(width:int, height:int, pointCount:int):Vector.<Point> {
            var m:int = 20;
            var vec:Vector.<Point> = new Vector.<Point>();
            for (var i:int = 0; i < pointCount; i++)
                vec.push(new Point(m + int(Math.random() * (width - m * 2)), m + int(Math.random() * (height - m * 2))));
            return vec;
        }
    }
}
