import Foundation

func stripStringOfSpaces(_ str: String.SubSequence) -> String {
    let result = str.trimmingCharacters(in: .whitespaces)
    return result
}

let outputDir = "/Users/michel/Desktop/Quasicode/Interpreter/QuasicodeInterpreter/Sources/QuasicodeInterpreter/AstClasses"

struct VisitorType {
    internal init(type: String? = nil, displayType: String? = nil, throwable: Bool) {
        self.type = type
        self.displayType = displayType
        self.throwable = throwable
    }
    
    internal init(type: String? = nil, throwable: Bool) {
        self.type = type
        self.displayType = type
        self.throwable = throwable
    }
    
    var type: String?
    var displayType: String?
    var throwable: Bool
}

defineAst(outputDir: outputDir, baseName: "AstType", typed: false, includesLocation: true, types: [
    "AstArrayType        ; contains: AstType",
    "AstClassType        ; name: Token, templateArguments: [AstType]?",
    "AstTemplateTypeName ; belongingClass: String, name: Token",
    "AstIntType          ; ",
    "AstDoubleType       ; ",
    "AstBooleanType      ; ",
    "AstAnyType          ; ",
], visitorTypes: [
    .init(type: nil, throwable: false),
    .init(type: "String", throwable: false),
    .init(type: "AstType", throwable: true),
    .init(type: "QsType", throwable: false)
])

defineAst(outputDir: outputDir, baseName: "Expr", typed: true, includesLocation: true, types: [
    "GroupingExpr        ; expression: Expr",
    "LiteralExpr         ; value: Any?",
    "ArrayLiteralExpr    ; values: [Expr]",
    "StaticClassExpr     ; classType: AstClassType, classId: Int?",
    "ThisExpr            ; keyword: Token, symbolTableIndex: Int?",
    "SuperExpr           ; keyword: Token, property: Token, superClassId: Int?, propertyId: Int?",
    "VariableExpr        ; name: Token, symbolTableIndex: Int?",
    "SubscriptExpr       ; expression: Expr, index: Expr",
    "CallExpr            ; object: Expr?, property: Token, paren: Token, arguments: [Expr], uniqueFunctionCall: Int?, polymorphicCallClassIdToIdDict: [Int : Int]?",
    "GetExpr             ; object: Expr, property: Token, propertyId: Int?",
    "UnaryExpr           ; opr: Token, right: Expr",
    "CastExpr            ; toType: AstType, value: Expr",
    "ArrayAllocationExpr ; baseType: AstType, contains: AstType, capacity: [Expr]",
    "ClassAllocationExpr ; classType: AstClassType, arguments: [Expr], callsFunction: Int?",
    "BinaryExpr          ; left: Expr, opr: Token, right: Expr",
    "LogicalExpr         ; left: Expr, opr: Token, right: Expr",
    "VariableToSetExpr   ; to: VariableExpr, annotationColon: Token?, annotation: AstType?, isFirstAssignment: Bool?",
    "IsTypeExpr          ; left: Expr, keyword: Token, right: AstType, rightType: QsType?",
    "ImplicitCastExpr    ; expression: Expr"
], visitorTypes: [
    .init(type: nil, throwable: false),
    .init(type: nil, throwable: true),
    .init(type: "QsType", throwable: true),
    .init(type: "Expr", throwable: true),
    .init(type: "String", throwable: false),
    .init(type: "Any?", displayType: "OptionalAny", throwable: true),
    .init(type: "Bool", throwable: false)
])

defineAst(outputDir: outputDir, baseName: "Stmt", typed: false, includesLocation: true, types: [
    "ClassStmt           ; keyword: Token, name: Token, endToken: Token, builtin: Bool, symbolTableIndex: Int?, instanceThisSymbolTableIndex: Int?, staticThisSymbolTableIndex: Int?, scopeIndex: Int?, templateParameters: [Token]?, expandedTemplateParameters: [AstType]?, superclass: AstClassType?, methods: [MethodStmt], fields: [AstClassField]",
    "MethodStmt          ; isStatic: Bool, staticKeyword: Token?, visibilityModifier: VisibilityModifier, function: FunctionStmt",
    "FunctionStmt        ; keyword: Token, name: Token, endToken: Token, symbolTableIndex: Int?, nameSymbolTableIndex: Int?, scopeIndex: Int?, params: [AstFunctionParam], annotation: AstType?, body: [Stmt], endOfFunction: Token",
    "ExpressionStmt      ; expression: Expr",
    "IfStmt              ; condition: Expr, thenBranch: BlockStmt, elseIfBranches: [IfStmt], elseBranch: BlockStmt?",
    "OutputStmt          ; expressions: [Expr]",
    "InputStmt           ; expressions: [Expr]",
    "ReturnStmt          ; keyword: Token, value: Expr?",
    "LoopFromStmt        ; variable: VariableExpr, loopScopeIndex: Int?, lRange: Expr, rRange: Expr, body: BlockStmt",
    "WhileStmt           ; expression: Expr, isDesugaredUntil: Bool, body: BlockStmt",
    "BreakStmt           ; keyword: Token",
    "ContinueStmt        ; keyword: Token",
    "BlockStmt           ; statements: [Stmt], scopeIndex: Int?, justBeyondEndOfStatements: InterpreterLocation",
    "ExitStmt            ; keyword: Token",
    "MultiSetStmt        ; setStmts: [SetStmt]", // assignments separated by a comma
    "SetStmt             ; left: Expr, chained: [Expr], value: Expr, typeChecked: Bool"
], visitorTypes: [
    .init(type: nil, throwable: false),
    .init(type: nil, throwable: true),
    .init(type: "Stmt", throwable: false),
    .init(type: "String", throwable: false),
    .init(type: "Bool", throwable: false)
])

func indent(_ indentLevel: Int = 1) -> String {
    var value = ""
    for _ in 0..<indentLevel {
        value = value + "    "
    }
    return value
}

func acceptFunctionSignature(baseName: String, visitorType: VisitorType, isPublic: Bool = true) -> String {
    return (isPublic ? "public " : "")+"func accept(visitor: \(baseName)\(visitorType.displayType ?? "")\(visitorType.throwable ? "Throw" : "")Visitor)\(visitorType.throwable ? " throws" : "")\(visitorType.type == nil ? "" : " -> \(visitorType.type!)")"
}

struct Variable {
    var name: String
    var type: String
}

func defineAst(outputDir: String, baseName: String, typed: Bool, includesLocation: Bool, types: [String], visitorTypes: [VisitorType]) {
    
    let path = "\(outputDir)/\(baseName).swift"
    
    var out = "// swiftlint:disable all\n"
    
    out += """
public protocol \(baseName) {

"""
    
    for visitorType in visitorTypes {
        out += indent()+acceptFunctionSignature(baseName: baseName, visitorType: visitorType, isPublic: false) + "\n"
    }
    
    if typed {
        out += """
        func fallbackToErrorType(assignable: Bool)
        var type: QsType? { get set }
    
    """
    }
    if includesLocation {
        out += """
        var startLocation: InterpreterLocation { get set }
        var endLocation: InterpreterLocation { get set }
    
    """
    }
    
    out += """
}


"""
    
    defineVisitor(out: &out, baseName: baseName, types: types, visitorTypes: visitorTypes)
    
    for type in types {
        let typeInformation = type.split(separator: ";")
        let className = stripStringOfSpaces(typeInformation[0])
        var fields = stripStringOfSpaces(typeInformation[1]).split(separator: ",")
        var fieldList: [Variable] = []
        for field in fields {
            let strippedField = stripStringOfSpaces(field)
            let fieldSeparator = strippedField.firstIndex(of: ":")!
            let afterFieldSeparator = strippedField.index(fieldSeparator, offsetBy: 1)
            fieldList.append(.init(name: String(stripStringOfSpaces(strippedField[strippedField.startIndex..<fieldSeparator])), type: String(stripStringOfSpaces(strippedField[afterFieldSeparator...]))))
        }
        if typed {
            fieldList.append(.init(name: "type", type: "QsType?"))
        }
        if includesLocation {
            fieldList.append(.init(name: "startLocation", type: "InterpreterLocation"))
            fieldList.append(.init(name: "endLocation", type: "InterpreterLocation"))
        }
        
        defineType(out: &out, baseName: baseName, className: String(className), includeFallbackToErrorType: typed, fieldList: fieldList, visitorTypes: visitorTypes)
    }
    
    do {
        try out.write(to: .init(fileURLWithPath: path), atomically: false, encoding: .utf8)
    } catch {
        print(error)
    }
}

func defineVisitor(out: inout String, baseName: String, types: [String], visitorTypes: [VisitorType]) {
    
    for visitorType in visitorTypes {
        out+="""
    public protocol \(baseName)\(visitorType.displayType ?? "")\(visitorType.throwable ? "Throw" : "")Visitor {

    """
        for type in types {
            let typeName = stripStringOfSpaces(type.split(separator: ";")[0])
            out+="""
        func visit\(typeName)\(visitorType.displayType ?? "")(\(baseName.lowercased()): \(typeName))\(visitorType.throwable ? " throws" : "") \(visitorType.type == nil ? "" : "-> \(visitorType.type!)")

    """
        }
        out+="""
    }


    """
    }
}

func defineType(out: inout String, baseName: String, className: String, includeFallbackToErrorType: Bool, fieldList: [Variable], visitorTypes: [VisitorType]) {
    out+="""
public class \(className): \(baseName) {

"""
    print(className)
    // the fields
    for field in fieldList {
        out+="""
    public var \(field.name): \(field.type)

"""
        print("+ \(field.name): \(field.type)")
    }
    print()
    
    // initializer
    let initializerList = fieldList.reduce("", { partialResult, next in
        var result = partialResult
        if partialResult != "" {
            result += ", "
        }
        result+="\(next.name): \(next.type)"
        return result
    })
    out+="""
    
    init(\(initializerList)) {

"""
    for field in fieldList {
        out+="\(indent(2))self.\(field.name) = \(field.name)\n"
    }
    out+="""
    }

"""
    
    // copying initializer
    out+="""
    init(_ objectToCopy: \(className)) {

"""
    for field in fieldList {
        out+="\(indent(2))self.\(field.name) = objectToCopy.\(field.name)\n"
    }
    out+="""
    }


"""
    
    // the fallback method
    if includeFallbackToErrorType {
        out+="""
            public func fallbackToErrorType(assignable: Bool) {
                if self.type == nil {
                    self.type = QsErrorType(assignable: assignable)
                }
            }
        
        
        """
    }
    // the accept method
    for visitorType in visitorTypes {
        out+="""
    \(acceptFunctionSignature(baseName: baseName, visitorType: visitorType)) {
        \(visitorType.throwable ? "try " : "")visitor.visit\(className)\(visitorType.displayType ?? "")(\(baseName.lowercased()): self)
    }

"""
    }
    out+="""
}


"""
    
}
