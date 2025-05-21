// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract School {
    // 管理员地址
    address public admin;
    
    // 学生信息结构体
    struct Student {
        string name;
        uint256 age;
        bool hasStudentStatus;
    }
    
    // 使用 mapping 存储学生信息
    mapping(address => Student) public students;
    
    // 使用 mapping 存储所有学生地址
    mapping(uint256 => address) public studentAddresses;
    
    // 学生总数
    uint256 public studentCount;
    
    // 事件：添加学生
    event StudentAdded(address indexed student, string name, uint256 age);
    // 事件：删除学生
    event StudentRemoved(address indexed student);
    
    constructor() {
        admin = msg.sender;
    }
    
    // 修饰器：只有管理员可以调用
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    // 添加学生
    function addStudent(address _student, string memory _name, uint256 _age) external onlyAdmin {
        require(_student != address(0), "Invalid address");
        require(!students[_student].hasStudentStatus, "Student already exists");
        
        students[_student] = Student({
            name: _name,
            age: _age,
            hasStudentStatus: true
        });
        
        studentAddresses[studentCount] = _student;
        studentCount++;
        
        emit StudentAdded(_student, _name, _age);
    }
    
    // 删除学生
    function removeStudent(address _student) external onlyAdmin {
        require(students[_student].hasStudentStatus, "Student does not exist");
        
        // 将学生信息标记为已删除
        students[_student].hasStudentStatus = false;
        
        // 从地址映射中删除
        for (uint256 i = 0; i < studentCount; i++) {
            if (studentAddresses[i] == _student) {
                // 将最后一个地址移到当前位置
                studentAddresses[i] = studentAddresses[studentCount - 1];
                delete studentAddresses[studentCount - 1];
                studentCount--;
                break;
            }
        }
        
        emit StudentRemoved(_student);
    }
    
    // 检查地址是否是学生
    function isStudent(address _student) external view returns (bool) {
        return students[_student].hasStudentStatus;
    }
    
    // 获取学生信息
    function getStudentInfo(address _student) external view returns (
        string memory name,
        uint256 age
    ) {
        Student memory info = students[_student];
        return (info.name, info.age);
    }
    
    // 获取所有学生数量
    function getStudentCount() external view returns (uint256) {
        return studentCount;
    }
    
    // 获取指定索引的学生地址
    function getStudentAddress(uint256 index) external view returns (address) {
        require(index < studentCount, "Index out of bounds");
        return studentAddresses[index];
    }
} 