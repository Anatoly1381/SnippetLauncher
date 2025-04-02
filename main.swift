//
//  main.swift
//  ConsoleApp
//
//  Created by Anatoly Fedorov on 19/3/2568 BE.
//



import SwiftUI
func greet(name: String) {
    print("Привет! \(name) Добро пожаловать в Swift.")
}
greet(name: "Анатолий")
var myName: String = "Анатолий"
greet(name: myName)
print("Ввведите ваше имя")
if let userName = readLine() {
    greet(name: userName)
}
print("Введите ваше имя:")
if let userName = readLine(), !userName.isEmpty {
    greet(name: userName)
} else {
print( "Вы не ввели имя! Попробуйте ещё раз.")
    }
