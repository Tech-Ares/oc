package com.omnichat;

public class Application {
    public static void main(String[] args) {
        System.out.println("Hello, Omnichat!");
        while (true) {
            try {
                Thread.sleep(5000);
                System.out.println("Service running...");
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
