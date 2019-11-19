package {
    import flash.geom.Point;
    import flash.geom.Rectangle;

    public class QuadTree {
        public var bounds:Rectangle;
        public var point:Point;
        public var divided:Boolean = false;
        public var quads:Array;

        private var topLeft:QuadTree;
        private var topRight:QuadTree;
        private var bottomLeft:QuadTree;
        private var bottomRight:QuadTree;

        public function QuadTree(bounds:Rectangle) {
            this.bounds = bounds;
            quads = [];
        }

        public function query(range:Rectangle):Array {
            var found:Array = [];
            if (!bounds.intersects(range))
                return found;

            if (divided) {
                found = found.concat(topLeft.query(range), topRight.query(range), bottomLeft.query(range), bottomRight.query(range));
            } else if (point && range.contains(point.x, point.y)) {
                found.push(point);
            }

            return found;
        }

        public function insert(point:Point):Boolean {
            if (!bounds.contains(point.x, point.y))
                return false;

            if (!this.point && quads.length == 0) {
                this.point = point;
            } else {
                if (!divided)
                    divide();

                // Send this point to the child quads
                for each (var q:QuadTree in quads)
                    if (q.insert(point))
                        return true;
            }

            return false;
        }

        private function divide():void {
            topLeft = new QuadTree(new Rectangle(bounds.x, bounds.y, bounds.width / 2, bounds.height / 2));
            topRight = new QuadTree(new Rectangle(bounds.x + bounds.width / 2, bounds.y, bounds.width / 2, bounds.height / 2));
            bottomLeft = new QuadTree(new Rectangle(bounds.x, bounds.y + bounds.height / 2, bounds.width / 2, bounds.height / 2));
            bottomRight = new QuadTree(new Rectangle(bounds.x + bounds.width / 2, bounds.y + bounds.height / 2, bounds.width / 2, bounds.height / 2));

            quads.push(topLeft, topRight, bottomLeft, bottomRight);

            // Send this point to the child quads
            for each (var q:QuadTree in quads)
                q.insert(point.clone());
            point = null;

            divided = true;
        }
    }
}