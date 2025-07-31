package myDatabase

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"k8s.io/client-go/kubernetes"
)

// DeleteDatabase deletes a PostgreSQL cluster
func DeleteDatabase(w http.ResponseWriter, r *http.Request, clientset *kubernetes.Clientset) {
	// Check Json
	var req DatabaseRequest
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, "Failed to parse JSON", http.StatusBadRequest)
		return
	}

	namespace := "postgres-operator"
	clusterName := fmt.Sprintf("postgres-cluster-%s", req.Username)
	restClient := clientset.RESTClient()

	// Delete the PostgreSQL cluster
	result := restClient.
		Delete().
		AbsPath("/apis/postgres-operator.crunchydata.com/v1beta1").
		Namespace(namespace).
		Resource("postgresclusters").
		Name(clusterName).
		Do(context.TODO())

	// Error handling
	if result.Error() != nil {
		http.Error(w, fmt.Sprintf("Failed to delete database: %v", result.Error()), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "Successfully deleted database cluster: %s", clusterName)
}
