int main() {
    int a;
    a = 100; 

    if (a > 50) {
        int a;   // Shadows the outer 'a'
        a = 5;   
        int b;
        b = a + 10; // Uses inner 'a' (5)
    }

    a = a + 1; // Uses outer 'a' (100)
    return a;
}