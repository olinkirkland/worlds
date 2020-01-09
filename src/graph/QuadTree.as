package graph {
    import flash.geom.Point;
    import flash.geom.Rectangle;


    public class QuadTree {
        public var bounds:Rectangle;
        public var point:Point;
        public var divided:Boolean = false;

        private var topLeft:QuadTree;
        private var topRight:QuadTree;
        private var bottomLeft:QuadTree;
        private var bottomRight:QuadTree;


        public function QuadTree(bounds:Rectangle) {
            this.bounds = bounds;
        }


        public function query(range:Rectangle):Array {
            var found:Array = [];
            if (!bounds.intersects(range)) {
                return found;
            }

            if (divided) {
                found = found.concat(topLeft.query(range), topRight.query(range), bottomLeft.query(range), bottomRight.query(range));
            } else if (point && range.contains(point.x, point.y)) {
                found.push(point);
            }

            return found;
        }

        public function queryFromPoint(point:Point, diameter:Number):Array {
            return query(new Rectangle(point.x - diameter / 2, point.y - diameter / 2, diameter, diameter));
        }


        public function insert(p:Point):Boolean {
            if (!bounds.contains(p.x, p.y))
                return false;

            if (!point && !divided) {
                point = p;
            } else {
                if (!divided)
                    divide();

                // Send this point to the child quads
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

            // Send this point to the child quads
            topLeft.insert(point.clone());
            topRight.insert(point.clone());
            bottomLeft.insert(point.clone());
            bottomRight.insert(point.clone());

            point = null;

            divided = true;
        }
    }
}