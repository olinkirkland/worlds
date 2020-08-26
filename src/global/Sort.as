package global
{
    import graph.Cell;

    import layers.geography.hydrology.River;

    public class Sort
    {
        public static function cellByElevation(n1:Cell, n2:Cell):Number
        {
            if (n1.elevation > n2.elevation)
                return 1;
            else if (n1.elevation < n2.elevation)
                return -1;
            else
                return objectByIndex(n1, n2);
        }

        public static function objectByIndex(n1:Object, n2:Object):Number
        {
            if (n1.index > n2.index)
                return 1;
            else if (n1.index < n2.index)
                return -1;
            else
                return 0;
        }

        public static function riverByLength(n1:River, n2:River):Number
        {
            if (n1.cells.length > n2.cells.length)
                return 1;
            else if (n1.cells.length < n2.cells.length)
                return -1;
            else
                return 0;
        }
    }
}
