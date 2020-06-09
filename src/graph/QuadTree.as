package graph {
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import spark.primitives.Rect;

    public class QuadTree {
        private const cap:int = 50;

        public var bounds:Rectangle;
        public var points:Vector.<Point>;
        public var divided:Boolean = false;

        private var topLeft:QuadTree;
        private var topRight:QuadTree;
        private var bottomLeft:QuadTree;
        private var bottomRight:QuadTree;

        public function QuadTree(bounds:Rectangle) {
            this.bounds = bounds;
            points = new Vector.<Point>();
        }


        public function query(range:Rectangle):Vector.<Point> {
            var found:Vector.<Point> = new Vector.<Point>();
            if (!bounds.intersects(range))
                return found;

            if (divided)
                found = found.concat(topLeft.query(range), topRight.query(range), bottomLeft.query(range), bottomRight.query(range));
            else if (points)
                for each (var p:Point in points)
                    if (range.contains(p.x, p.y))
                        found.push(p);

            return found;
        }

        public function isRangePopulated(range:Rectangle):Boolean {
            if (!bounds.intersects(range))
                return false;

            if (divided)
                return topLeft.isRangePopulated(range) || topRight.isRangePopulated(range) || bottomLeft.isRangePopulated(range) || bottomRight.isRangePopulated(range);
            else {
                for each (var p:Point in points)
                    if (range.contains(p.x, p.y))
                        return true;
            }

            return false;
        }

        public function queryFromPoint(point:Point, radius:Number):Vector.<Point> {
            return query(new Rectangle(point.x - radius, point.y - radius, radius * 2, radius * 2));
        }


        public function insert(p:Point):Boolean {
            if (!bounds.contains(p.x, p.y))
                return false;

            if (!divided) {
                points.push(p);

                // Does it need to be divided?
                if (points.length >= cap)
                    divide();
                else
                    return true;
            }

            if (divided) {
                // Send this point to the divided quads
                if (topLeft.insert(p) || topRight.insert(p) || bottomLeft.insert(p) || bottomRight.insert(p))
                    return true;
            }
            return false;
        }


        private function divide():void {
            topLeft = new QuadTree(new Rectangle(bounds.x, bounds.y, bounds.width / 2, bounds.height / 2));
            topRight = new QuadTree(new Rectangle(bounds.x + bounds.width / 2, bounds.y, bounds.width / 2, bounds.height / 2));
            bottomLeft = new QuadTree(new Rectangle(bounds.x, bounds.y + bounds.height / 2, bounds.width / 2, bounds.height / 2));
            bottomRight = new QuadTree(new Rectangle(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2, bounds.width / 2, bounds.height / 2));

            // Send the points to the divided quads
            for each (var p:Point in points)
                if (topLeft.insert(p) || topRight.insert(p) || bottomLeft.insert(p) || bottomRight.insert(p))
                    continue;
            points = null;

            divided = true;
        }
    }
}