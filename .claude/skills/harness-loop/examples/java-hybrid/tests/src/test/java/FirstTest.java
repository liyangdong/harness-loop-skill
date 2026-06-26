package com.example;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * First test - intentionally passing.
 * Demonstrates TDD green phase: replace with your own failing test, then implement.
 *
 * This placeholder exists so `mvn -q test` succeeds on iteration 0 (project
 * bootstrap). Delete or rewrite it as soon as the first real test exists.
 */
class FirstTest {

    @Test
    @DisplayName("placeholder test should pass after implementation")
    void placeholder() {
        // This test actually passes - 1+1=2.
        // Replace this assertion with real test logic.
        assertEquals(2, 1 + 1, "math works");
    }
}
