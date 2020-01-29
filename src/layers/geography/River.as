package layers.geography {
    import graph.Cell;

    public class River {
        public var index:int;
        public var cells:Vector.<Cell>;
        public var end:Cell;
        public var type:String;

        public function River() {
            cells = new Vector.<Cell>();
        }

        public function addCell(cell:Cell):void {
            cell.rivers.push(this);
            cells.push(cell);
        }
    }
}
