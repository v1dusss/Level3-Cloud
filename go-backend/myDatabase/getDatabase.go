package myDatabase

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"k8s.io/client-go/kubernetes"
)

func GetDatabase(w http.ResponseWriter, r *http.Request, clientset *kubernetes.Clientset) {
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

	// Get the PostgreSQL cluster
	result := restClient.
		Get().
		AbsPath("/apis/postgres-operator.crunchydata.com/v1beta1").
		Namespace(namespace).
		Resource("postgresclusters").
		Name(clusterName).
		Do(context.TODO())

	if result.Error() != nil {
		http.Error(w, fmt.Sprintf("Failed to get database: %v", result.Error()), http.StatusInternalServerError)
		return
	}

	data, err := result.Raw()
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to read response: %v", err), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.Write(data)
}
