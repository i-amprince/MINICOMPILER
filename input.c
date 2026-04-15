int main() {
    int a;
    a = 100; // Global 'a'

    if (a > 50) {
        int a;   // Local 'a' (Shadows the global one!)
        int b;
        a = 5;   // Modifies the local 'a'
        b = a + 10;
    }

    // Back in global scope! The local 'a' and 'b' are dead.
    // This will modify the original 'a' (100)
    a = a + 1; 

    for (int i = 0; i<4; i++){
        a++;
    }
    return a;
}