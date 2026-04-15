int main() {
    int x;
    int y;
    int z;
    
    // Constant folding and propagation
    x = 10 + 20; 
    y = x * 2;   
    
    // Dead code (these will be eliminated by DCE)
    int unused;
    unused = 999;
    
    z = y - x;
    return z;
}