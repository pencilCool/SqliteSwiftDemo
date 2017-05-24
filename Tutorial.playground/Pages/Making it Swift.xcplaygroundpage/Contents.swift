//: Back to [The C API](@previous)

import Foundation
import SQLite
import PlaygroundSupport

destroyPart2Database()

//: # Making it Swift


//: ## Errors

enum SQLiteError: Error {
    
    case OpenDatabase(message: String)
    case Prepare(message: String)
    case Step(message: String)
    case Bind(message: String)
    
}

//: ## The Database Connection
class SQLiteDatabase {
    private let dbPointer: OpaquePointer
    private init(dbPointer: OpaquePointer) {
        self.dbPointer = dbPointer
    }
    
    deinit {
        sqlite3_close(dbPointer)
    }
    
    static func open(path: String) throws -> SQLiteDatabase {
        
        var db: OpaquePointer?
        
        if sqlite3_open(path, &db) == SQLITE_OK {
            
            return SQLiteDatabase(dbPointer: db!)
        } else {
            defer {
                if db != nil {
                    sqlite3_close(db)
                }
            }
            
            if  sqlite3_errmsg(db) != nil {
                let message = String(cString: sqlite3_errmsg(db))
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
    private var errorMesage: String{
        if let errorMessage = String(cString: sqlite3_errmsg(dbPointer)) {
            return errorMessage
        } else {
            return "NO error message proveide from sqlite."
        }
    }
}



let db: SQLiteDatabase

do {
    db = try SQLiteDatabase.open(path: part2DbPath)
    print("Successfully opened connection to database.")
} catch SQLiteError.OpenDatabase(let message) {
    print("Unable to open database. Verify that you created the directory described in the Getting Started section.")
    PlaygroundPage.current.finishExecution()
}



//: ## Preparing Statements




//: ## Create Table


//: ## Insert Row


//: ## Read
