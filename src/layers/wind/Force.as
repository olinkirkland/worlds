package layers.wind
{
    public class Force
    {
        public var angle:Number;
        public var strength:Number;

        public function Force(angle:Number = 0, strength:Number = 0)
        {
            this.angle = angle;
            this.strength = strength;
        }

        public function merge(force:Force):void
        {
            // Merge another force into this one
        }
    }
}
