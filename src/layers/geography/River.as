package layers.geography
{
    import graph.Cell;

    public class River
    {
        public static const STEM:String = "stem";
        public static const TRIBUTARY:String = "tributary";

        public var index:int;
        public var cells:Vector.<Cell>;
        public var start:Cell;
        public var end:Cell;

        public var type:String;

        public var invalid:Boolean = false;

        public function River()
        {
            cells = new Vector.<Cell>();
        }

        public function addCell(cell:Cell):void
        {
            if (cells.length == 0)
                start = cell;

            cell.rivers.push(this);
            cells.push(cell);
        }
    }
}
