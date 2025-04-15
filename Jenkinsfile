pipeline {
    agent any
    stages {

        stage('Setup test environment') {
            steps {
                sh '''
                # 1. Force remove specific containers if they exist
                docker rm -f mysql_db wordpress_app wp_cli 2>/dev/null || true
                                
                docker-compose up -d
                '''
            }
        }
        stage('Wait for WordPress') {
            steps {
                script {
                    def maxAttempts = 20
                    def attempt = 1
                    while (attempt <= maxAttempts) {
                        try {
                            sh 'docker exec wordpress_app curl -s localhost'
                            echo "WordPress is ready!"
                            break
                        } catch (Exception e) {
                            echo "Attempt ${attempt}: WordPress not ready yet, waiting..."
                            sleep time: 10, unit: 'SECONDS'
                            attempt++
                        }
                    }
                    if (attempt > maxAttempts) {
                        error "WordPress did not become ready after ${maxAttempts} attempts."
                    }
                }
            }
        }

        



       
        stage('Run WP-CLI Tests') {
            steps {
                sh '''
                docker-compose exec -T wp-cli bash -c '
                wp --require=/var/www/html/wp-cli-test-command.php test
                '
                '''

            }
        }

        stage('Tear Down Test Environment') {
            steps {
                sh 'docker-compose down'
            }
        }
        stage('Deploy to Production') {
            steps {
                sh 'docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d'
            }
        }

        // stage('Remove WP-CLI Container') {
        //     steps {
        //         sh 'docker rm -f wp_cli || true'
        //     }
        // }


    }
    post {
        always {
            cleanWs()
        }
    }
}


