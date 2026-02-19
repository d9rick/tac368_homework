
// coords for a chess board. left column first, matches a,b,c of
// real chess moves.  Then row number from the bottom, except 
// starting with 0 instead of 1.  
class Coords
{
  int c;
  int r;

  Coords( this.c, this.r );

  bool equals( Coords there )
  { return there.c==c && there.r==r;
  }
}