using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;

namespace ApplicationCacheExample
{
    public class Node
    {
        public Node Next;
        public SqlCommand Value;
    }
    class TranCaching 
    {       
        private Node head;
        private Node current;//This will have latest node
        public int Count;
        public TranCaching()
        {
            head = new Node();
            current = head;
        }

        public void AddAtLast(SqlCommand data)
        {
            Node newNode = new Node();
            newNode.Value = data;
            current.Next = newNode;
            current = newNode;
            Count++;
        }
        public SqlCommand GetNode()
        {
            
            SqlCommand command = head.Next.Value;
            head.Next = head.Next.Next;
            Count--;

            return command;
        }
    }
}
