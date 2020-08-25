package layers.geography
{
    public class Hydrology
    {
        private var map:Map;
        public var rivers:Vector.<River>;

        public function Hydrology(map:Map)
        {
            this.map = map;
            rivers = new Vector.<River>();
        }

        public function addRiver():River
        {
            var river:River = new River();
            river.type = River.STEM;
            river.index = rivers.length;
            rivers.push(river);
            return river;
        }
    }
}