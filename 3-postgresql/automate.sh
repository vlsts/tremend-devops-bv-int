#!/bin/bash

echo "PostgreSQL Database Automation Script"

# Get user input for database host or use default localhost
read -p "Enter database host (default: localhost): " DB_HOST
DB_HOST=${DB_HOST:-localhost}

# Get user input for PostgreSQL password
read -s -p "Enter PostgreSQL password: " POSTGRES_PASSWORD
echo

# Get user input for database name
read -p "Enter database name: " DB_NAME
# Check if database name is empty and exit if so
if [[ -z "$DB_NAME" ]]; then
    echo "Error: Database name cannot be empty"
    exit 1
fi

# Get user input for dump file path
read -p "Enter path to SQL dump file: " DUMP_FILE
# Check if dump file exists and exit if not
if [[ ! -f "$DUMP_FILE" ]]; then
    echo "Error: Dump file does not exist"
    exit 1
fi

# Set default database owner to ps_cee
DB_OWNER="ps_cee"

# Set up admin user ps_cee
echo "Creating admin user ps_cee..."
read -s -p "Enter password for admin user ps_cee: " PS_CEE_PASSWORD
echo
# Check if password is empty and exit if so
if [[ -z "$PS_CEE_PASSWORD" ]]; then
    echo "Error: Password cannot be empty"
    exit 1
fi

# Create the admin user if it does not exist, need to use PGPASSWORD as psql does not support password input from params
PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$DB_HOST" -U postgres -c "CREATE USER $DB_OWNER WITH PASSWORD '$PS_CEE_PASSWORD' CREATEDB;" || {
    echo "Admin user ps_cee already exists or could not be created"
}

# Create the database with ps_cee as owner
echo "Creating database $DB_NAME..."
# Need to use PGPASSWORD as psql does not support password input from params
PGPASSWORD="$PS_CEE_PASSWORD" createdb -h "$DB_HOST" -U $DB_OWNER "$DB_NAME" -O "$DB_OWNER" || {
    echo "Error: Failed to create database"
    exit 1
}

# Import the SQL dump file
echo "Importing SQL dump from $DUMP_FILE..."
# Need to use PGPASSWORD as psql does not support password input from params
PGPASSWORD="$PS_CEE_PASSWORD" psql -h "$DB_HOST" -U $DB_OWNER -d "$DB_NAME" -f "$DUMP_FILE" || {
    echo "Error: Failed to import SQL dump"
    exit 1
}

# Create logs directory
mkdir -p logs

# Execute and log SQL queries
# The queries are identical to the ones in the README with the exception of Query 2 which reads the department name from user input
echo "Executing SQL queries..."

# Query 1: Total number of employees
echo "Running Query 1: Total number of employees"
PGPASSWORD="$PS_CEE_PASSWORD" psql -h "$DB_HOST" -U $DB_OWNER -d "$DB_NAME" -c "SELECT count(*) FROM employees;" > logs/employee_count.log
echo "Table list saved to logs/employee_count.log"

# Query 2: Retrieve the names of employees in a specific department read from user input
echo "Running Query 2: Retrieve the names of employees in a specific department"
read -p "Enter department name for query: " DEPARTMENT_NAME
PGPASSWORD="$PS_CEE_PASSWORD" psql -h "$DB_HOST" -U $DB_OWNER -d "$DB_NAME" -c "
SELECT e.employee_id, e.first_name, e.last_name, d.department_name
FROM employees e
JOIN departments d ON e.department_id = d.department_id
WHERE d.department_name = '$DEPARTMENT_NAME';" > logs/employees_query.log
echo "Department query results saved to logs/employees_query.log"

# Query 3: Calculate the highest and lowest salaries per department
echo "Running Query 3: Calculate the highest and lowest salaries per department"
PGPASSWORD="$PS_CEE_PASSWORD" psql -h "$DB_HOST" -U $DB_OWNER -d "$DB_NAME" -c "
SELECT 
    d.department_name as \"Department\",
    MIN(s.salary) AS \"Lowest Salary\",
    MAX(s.salary) AS \"Highest Salary\"
FROM employees e
JOIN salaries s ON e.employee_id = s.employee_id
JOIN departments d ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY d.department_name;" > logs/salary_query.log
echo "Salary query results saved to logs/salary_query.log"

echo "Database setup completed successfully!"
