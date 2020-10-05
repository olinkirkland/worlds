package layers.geography.hydrology
{
    import graph.Cell;

    public class River
    {
        public static const STEM:String = "stem";
        public static const TRIBUTARY:String = "tributary";

        public var cells:Vector.<Cell>;
        public var start:Cell;
        public var end:Cell;

        public var type:String;

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

        public function removeCell(cell:Cell):void
        {
            cell.rivers.removeAt(cell.rivers.indexOf(this));
            cells.removeAt(cells.indexOf(cell));

            if (start == cell)
                start = cells.length > 0 ? cells[0] : null;

            if (end == cell)
                end = cells.length > 0 ? cells[cells.length - 1] : null;
        }

        public function removeAllCells():void
        {
            while (cells.length > 0)
                removeCell(cells[0]);
        }
    }
}
