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
    fileprivate let dbPointer: OpaquePointer
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
            
            if  let errorCString = sqlite3_errmsg(db) {
                let message = String(cString: errorCString)
                throw SQLiteError.OpenDatabase(message: message)
            } else {
                throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
            }
        }
    }
    
    fileprivate var errorMessage: String{
        if let errorCString = sqlite3_errmsg(dbPointer) {
            let errorMessage = String(cString: errorCString)
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

extension SQLiteDatabase {
    func prepareStatement(sql: String) throws ->  OpaquePointer {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(dbPointer, sql, -1, &statement, nil) == SQLITE_OK else {
            throw SQLiteError.Prepare(message: errorMessage)
        }
        return statement!
    }
}



//: ## Create Table

struct Contact {
    let id: Int32
    let name: String
}

protocol SQLTable {
    static var creatStatement: String { get }
}

extension Contact: SQLTable {
    static var creatStatement: String {
        return "CREATE TABLE Contact(" +
            "Id INT PRIMARY KEY NOT NULL," +
            "Name CHAR(255)" +
        ");"
    }
}

extension SQLiteDatabase {
    func createTable(table: SQLTable.Type)  throws  {
        
        let creatTabeStatement = try prepareStatement(sql: table.creatStatement)
        
        defer {
            sqlite3_finalize(creatTabeStatement)
        }
        
        guard sqlite3_step(creatTabeStatement) == SQLITE_DONE  else {
           throw SQLiteError.Step(message: errorMessage)
        }
        print("\(table) table created.")
    }
}

do {
    try db.createTable(table: Contact.self)
} catch {
    print(db.errorMessage)
}

//: ## Insert Row
extension SQLiteDatabase {
    func insertContact(_ contact: Contact) throws  {
        let insertSql = "INSERT INTO Contact (Id, Name) VALUES (?, ?);"
        let insertStatement = try prepareStatement(sql: insertSql)
        defer {
            sqlite3_finalize(insertStatement)
        }
        
        let name = contact.name as NSString
        guard sqlite3_bind_int(insertStatement, 1, contact.id) == SQLITE_OK  && sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil) == SQLITE_OK else {
            throw SQLiteError.Bind(message: errorMessage)
        }
        guard sqlite3_step(insertStatement) == SQLITE_DONE else {
            throw SQLiteError.Step(message: errorMessage)
        }
        
        print("Sucessfully inserted row.")
    }
}

do {
    try db.insertContact(Contact(id: 1,name: "Ray"))
} catch {
    print(db.errorMessage)
}



//: ## Read

extension SQLiteDatabase {
    func contact(id: Int32) -> Contact? {
        let querySql = "SELECT * FROM Contact WHERE Id = ?;"
        guard let queryStatement = try? prepareStatement(sql: querySql) else {
            return nil
        }
        
        defer {
            sqlite3_finalize(queryStatement)
        }
        
        guard sqlite3_bind_int(queryStatement, 1, id) == SQLITE_OK else {
            return nil
        }
        guard sqlite3_step(queryStatement) == SQLITE_ROW else {
            return nil
        }
        
        let id = sqlite3_column_int(queryStatement, 0)
        
        let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
        
        let name = String(cString: queryResultCol1!)
        return Contact(id: id, name: name)
    }
    
}

let first = db.contact(id: 1)
print(first)


